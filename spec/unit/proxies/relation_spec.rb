# -*- encoding : utf-8 -*-

require 'spec_helper'
require 'guacamole/proxies/relation'

describe Guacamole::Proxies::Relation do
  let(:model) { double('Model') }
  let(:edge_class) { double('EdgeClass') }
  let(:responsible_edge_collection) { double('EdgeCollection') }
  let(:edge_collection_name)        { 'name_of_the_edge_collection' }

  before do
    allow(Guacamole::EdgeCollection).to receive(:for).with(edge_class).and_return(responsible_edge_collection)
    allow(responsible_edge_collection).to receive(:collection_name).and_return(edge_collection_name)
  end

  context 'initialization' do
    subject { Guacamole::Proxies::Relation }

    it 'should take a model and edge class as params' do
      expect { subject.new(model, edge_class) }.not_to raise_error
    end
  end

  context 'initialized proxy' do
    let(:proxy_options) { {} }
    let(:neighbors) { double('Neighbors') }

    subject { Guacamole::Proxies::Relation.new(model, edge_class, proxy_options) }

    # The following is not possible with `its` because `send` is not available
    it 'should have an edge_collection' do
      expect(subject.edge_collection).to eq responsible_edge_collection
    end

    it 'should have a direction' do
      expect(subject.direction).to eq :outbound
    end

    it 'should know it the proxy relates to a collection' do
      expect(subject.relates_to_collection?).to eq true
    end

    context 'with relation to collection' do
      let(:proxy_options) { { just_one: false } }
      let(:related_models) { double('RelatedModels', count: 23) }

      before do
        allow(related_models).to receive(:to_a).and_return(neighbors)
        allow(responsible_edge_collection).to receive(:neighbors).
                                               with(model, subject.direction).
                                               and_return(related_models)
      end

      it 'should call the #neighbors method on the appropriate edge collection' do
        expect(subject.count).to eq related_models.count
      end
    end

    context 'with relation to single model' do
      let(:proxy_options) { { just_one: true } }
      let(:related_model) { double('RelatedModel', name: 'The Model') }

      before do
        allow(neighbors).to receive(:first).and_return(related_model)
        allow(neighbors).to receive(:to_a).and_return(neighbors)
        allow(responsible_edge_collection).to receive(:neighbors).
                                               with(model, subject.direction).
                                               and_return(neighbors)
      end

      it 'should call the #neighbors method on the appropriate edge collection' do
        expect(subject.name).to eq related_model.name
      end
    end
  end
end
