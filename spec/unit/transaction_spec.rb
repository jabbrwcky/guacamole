# -*- encoding : utf-8 -*-

require 'spec_helper'
require 'guacamole/transaction'

describe Guacamole::Transaction do
  let(:collection) { double('Collection') }
  let(:model) { double('Model') }
  let(:database) { double('Database') }
  let(:mapper) { double('Mapper') }
  let(:init_options) { { collection: collection, model: model } }

  before do
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
    subject { Guacamole::Transaction.new(init_options) }

    before do
      allow(collection).to receive(:connection)
    end

    its(:collection) { should eq collection }
    its(:model)      { should eq model }
    its(:mapper)     { should eq mapper }
    its(:database)   { should eq database }

    it 'should init the connection to the database' do
      expect(collection).to receive(:connection)

      Guacamole::Transaction.new(init_options)
    end
  end
end
