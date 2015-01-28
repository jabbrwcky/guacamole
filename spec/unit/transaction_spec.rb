# -*- encoding : utf-8 -*-

require 'spec_helper'
require 'guacamole/transaction'

describe Guacamole::Transaction::Vertex do
  let(:model) { double('Model') }
  let(:model_object_id) { double('ObjectId') }
  let(:model_key) { double('Key') }
  let(:model_id) { double('Id') }
  let(:collection) { double('Collection') }
  let(:document) { double('Document') }

  subject { Guacamole::Transaction::Vertex.new(model, collection, document) }

  before do
    allow(model).to receive(:object_id).and_return(model_object_id)
    allow(model).to receive(:key).and_return(model_key)
    allow(model).to receive(:_id).and_return(model_id)
  end

  it 'should return a hash to be used in the transaction code' do
    vertex_hash = {
                   object_id: model_object_id,
                   collection: collection,
                   document: document,
                   _key: model_key,
                   _id: model._id
                  }

    expect(subject.to_h).to eq vertex_hash
  end
end

describe Guacamole::Transaction do
  let(:collection) { double('Collection') }
  let(:model) { double('Model') }
  let(:database) { double('Database') }
  let(:mapper) { double('Mapper') }
  let(:init_options) { { collection: collection, model: model } }

  subject { Guacamole::Transaction.new(init_options) }

  before do
    allow(collection).to receive(:connection)
    allow(collection).to receive(:mapper).and_return(mapper)
    allow(collection).to receive(:database).and_return(database)
  end

  describe '#run' do
    subject { Guacamole::Transaction }

    let(:transaction_instance) { instance_double('Guacamole::Transaction') }

    it 'should build a new transaction and execute it' do
      allow(subject).to receive(:new).with(init_options).and_return(transaction_instance)
      expect(transaction_instance).to receive(:execute_transaction)

      subject.run(init_options)
    end
  end

  describe 'initialization' do
    its(:collection) { should eq collection }
    its(:model)      { should eq model }
    its(:mapper)     { should eq mapper }
    its(:database)   { should eq database }

    it 'should init the connection to the database' do
      expect(collection).to receive(:connection)

      Guacamole::Transaction.new(init_options)
    end
  end

  describe 'edge_collections for the transaction' do
    context 'with no edges present' do
      let(:vertex) { double('Vertex') }
      let(:collection_name) { 'awesome_collection' }
      let(:document) { double('Document') }
      let(:vertex) { double('Vertex') }

      before do
        allow(collection).to receive(:collection_name).and_return(collection_name)
        allow(mapper).to receive(:model_to_document).with(model).and_return(document)
        allow(mapper).to receive(:edge_attributes).and_return([])
        allow(Guacamole::Transaction::Vertex).to receive(:new).and_return(vertex)
        allow(vertex).to receive(:to_h).and_return(vertex)
      end

      its(:edges_present?) { should eq false }

      it 'should build a simple edge collection with just the model to be used if no edges are defined' do
        simple_edge_collection = {
                                  name: nil,
                                  fromVertices: [vertex],
                                  toVertices: [],
                                  edges: [],
                                  oldEdges: []
                                 }

        edge_collection = subject.simple_edge_collections
        expect(edge_collection).to eq [simple_edge_collection]
      end

      it 'should return the simple collections' do
        simple_edge_collections = double('SimpleEdgeCollections')
        allow(subject).to receive(:edges_present?).and_return(false)
        allow(subject).to receive(:simple_edge_collections).and_return(simple_edge_collections)

        expect(subject.edge_collections).to eq simple_edge_collections
      end
    end

    context 'with edges present' do
      let(:edge_attribute)  { double('EdgeAttribute') }
      let(:edge_attributes) { [edge_attribute] }
      let(:tx_edge_collection) { instance_double('Guacamole::Transaction::TxEdgeCollection') }
      let(:tx_edge_collection_as_hash) { double('Hash') }

      before do
        allow(mapper).to receive(:edge_attributes).and_return(edge_attributes)
        allow(tx_edge_collection).to receive(:to_h).and_return(tx_edge_collection_as_hash)
        allow(Guacamole::Transaction::TxEdgeCollection).to receive(:new).with(edge_attribute, model).and_return(tx_edge_collection)
      end

      its(:edges_present?) { should eq true }

      it 'should prepare each edge_attribute in the mapper' do
        expect(subject.full_edge_collections).to eq [tx_edge_collection_as_hash]
      end

      it 'should return the full collections' do
        full_edge_collections = double('FullEdgeCollections')
        allow(subject).to receive(:edges_present?).and_return(true)
        allow(subject).to receive(:full_edge_collections).and_return(full_edge_collections)

        expect(subject.edge_collections).to eq full_edge_collections
      end
    end
  end
end
