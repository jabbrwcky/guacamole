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

  its(:key) { should eq model_key }

  context 'with new vertex' do
    let(:model_id) { nil }

    its(:id) { should be model_object_id }
  end

  context 'with existing vertex' do
    its(:id) { should eq model_id }
  end

  it 'should return a hash to be used in the transaction code' do
    vertex_hash = {
                   object_id: model_object_id,
                   collection: collection,
                   document: document,
                   _key: model_key,
                   _id: model._id
                  }

    expect(subject.as_json).to eq vertex_hash
  end
end

describe Guacamole::Transaction::TargetStatesBuilder do
  subject { Guacamole::Transaction::TragetStatesBuilder }
end

describe Guacamole::Transaction::VertexTargetState do
  
end

describe Guacamole::Transaction::SubGraphTargetState do
  let(:model) { double('Model') }
  let(:model_id) { double('ModelId') }
  let(:from_model_class) { double('FromModelClass') }
  let(:to_model_class) { double('ToModelClass') }

  let(:from_collection) { double('Collection') }
  let(:from_collection_name) { double('CollectionName') }

  let(:to_collection) { double('Collection') }
  let(:to_collection_name) { double('CollectionName') }

  let(:edge_attribute) { double('EdgeAttribute') }
  let(:edge_class) { double('EdgeClass') }
  let(:edge_collection_class) { double('EdgeCollectionClass') }
  let(:edge_collection) { double('EdgeCollection') }
  let(:edge_collection_name) { double('EdgeCollectionName') }

  let(:from_document) { double('Document') }
  let(:to_document) { double('Document') }

  subject { Guacamole::Transaction::SubGraphTargetState.new(edge_attribute, model) }

  before do
    stub_const('Guacamole::EdgeCollection', edge_collection_class)

    allow(model).to receive(:_id).and_return(model_id)

    allow(edge_class).to receive(:from_collection).and_return(from_collection)
    allow(from_collection).to receive(:model_class).and_return(from_model_class)
    allow(from_collection).to receive(:collection_name).and_return(from_collection_name)

    allow(edge_class).to receive(:to_collection).and_return(to_collection)
    allow(to_collection).to receive(:model_class).and_return(to_model_class)
    allow(to_collection).to receive(:collection_name).and_return(to_collection_name)

    allow(edge_attribute).to receive(:edge_class).and_return(edge_class)
    allow(edge_collection_class).to receive(:for).and_return(edge_collection)
    allow(edge_collection).to receive(:collection_name).and_return(edge_collection_name)
  end

  its(:start_model) { should eq model }
  its(:edge_attribute) { should eq edge_attribute }
  its(:edge_collection) { should eq edge_collection }
  its(:edge_collection_name) { should eq edge_collection_name }
  its(:edge_class) { should eq edge_class }

  it 'should build a list of :to vertices with existing documents' do
    vertex_with_key    = double('Vertex', key: double)
    vertex_without_key = double('Vertex', key: nil)

    allow(subject).to receive(:to_vertices).and_return([vertex_with_key, vertex_without_key])

    expect(subject.to_vertices_with_only_existing_documents).to eq [vertex_without_key]
  end

  it 'should have a representation suitable for JSON serialization' do
    allow(subject).to receive(:from_vertices).and_return(from_vertices = double)
    allow(subject).to receive(:to_vertices_with_only_existing_documents).and_return(to_vertices = double)
    allow(subject).to receive(:edges).and_return(edges = double)
    allow(subject).to receive(:old_edge_keys).and_return(old_edge_keys = double)

    state_as_json = {
      name: edge_collection_name,
      fromVertices: from_vertices,
      toVertices: to_vertices,
      edges: edges,
      oldEdges: old_edge_keys
    }

    expect(subject.as_json).to eq state_as_json
  end

  it 'should select the responsible mapper for a given model' do
    expect(edge_collection).to receive(:mapper_for_start).with(model)

    subject.mapper_for_model(model)
  end

  it 'should map the given model to a document' do
    mapper = double('Mapper')
    allow(subject).to receive(:mapper_for_model).with(model).and_return(mapper)
    expect(mapper).to receive(:model_to_document).with(model)

    subject.model_to_document(model)
  end

  it 'should get a single related model of the edge_attribute as array' do
    related_model = double('Model')
    allow(edge_attribute).to receive(:get_value).with(model).and_return(related_model)

    expect(subject.related_models).to eq [related_model]
  end

  it 'should get multiple related models of the edge_attribute as array' do
    related_model1 = double('Model')
    related_model2 = double('Model')
    allow(edge_attribute).to receive(:get_value).with(model).and_return([related_model1, related_model2])

    expect(subject.related_models).to eq [related_model1, related_model2]
  end

  describe 'building of edges' do
    let(:from_vertex1) { double('Vertex', id: '42') }
    let(:from_vertex2) { double('Vertex', id: '23') }
    let(:to_vertex) { double('Vertex', id: '101') }

    before do
      allow(subject).to receive(:from_vertices).and_return([from_vertex1, from_vertex2])
      allow(subject).to receive(:to_vertices).and_return([to_vertex])
    end

    it 'should build a list of edges to connect all from vertices to the to vertices' do
      pattern = [
                 {
                  _from: from_vertex1.id,
                  _to: to_vertex.id
                 }.ignore_extra_keys!,
                 {
                  _from: from_vertex2.id,
                  _to: to_vertex.id
                 }.ignore_extra_keys!
                ]

      expect(subject.edges).to match_json_expression(pattern)
    end

    it 'should have a list of edges all with empty attributes' do
      expect(subject.edges).to all(include(attributes: {}))
    end
  end

  describe 'building of vertices' do
    let(:from_vertex) { double('Vertex') }
    let(:to_vertex) { double('Vertex') }
    let(:query_result) { double('Query') }

    before do
      allow(query_result).to receive(:key)
      allow(query_result).to receive(:map).and_yield(query_result)

      allow(subject).to receive(:model_to_document).with(from_model).and_return(from_document)
      allow(subject).to receive(:model_to_document).with(to_model).and_return(to_document)

      allow(Guacamole::Transaction::Vertex).to receive(:new)
                                                .with(from_model, from_collection_name, from_document)
                                                .and_return(from_vertex)
      allow(Guacamole::Transaction::Vertex).to receive(:new)
                                                .with(to_model, to_collection_name, to_document)
                                                .and_return(to_vertex)
    end

    context 'model is the :from part of the edge' do
      let(:from_model) { model }
      let(:to_model) { double('ToModel') }

      before do
        allow(from_model_class).to receive(:===).with(model).and_return(true)
        allow(to_model_class).to receive(:===).with(model).and_return(false)
        allow(subject).to receive(:related_models).and_return([to_model])
      end

      it 'should transform model to the :from vertices' do
        expect(subject.from_vertices).to eq [from_vertex]
      end

      it 'should transform the related models to :to vertices' do
        expect(subject.to_vertices).to eq [to_vertex]
      end

      it 'should select the old edge keys based on :from for the model' do
        expect(edge_collection).to receive(:by_example).with(_from: model_id).and_return(query_result)

        subject.old_edge_keys
      end
    end

    context 'model is the :to part of the edge' do
      let(:from_model) { double('FromModel') }
      let(:to_model) { model }

      before do
        allow(from_model_class).to receive(:===).with(model).and_return(false)
        allow(to_model_class).to receive(:===).with(model).and_return(true)
        allow(subject).to receive(:related_models).and_return([from_model])
      end

      it 'should transform model to the :to vertices' do
        expect(subject.to_vertices).to eq [to_vertex]
      end

      it 'should transform the related models to :from vertices' do
        expect(subject.from_vertices).to eq [from_vertex]
      end

      it 'should select the old edges based on :to for the model' do
        expect(edge_collection).to receive(:by_example).with(_to: model_id).and_return(query_result)

        subject.old_edge_keys
      end
    end
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
      let(:sub_graph_state) { instance_double('Guacamole::Transaction::SubGraphTargetState') }

      before do
        allow(mapper).to receive(:edge_attributes).and_return(edge_attributes)
        allow(Guacamole::Transaction::SubGraphTargetState).to receive(:new).with(edge_attribute, model).and_return(sub_graph_state)
      end

      its(:edges_present?) { should eq true }

      it 'should prepare each edge_attribute in the mapper' do
        expect(subject.full_edge_collections).to eq [sub_graph_state]
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
