# -*- encoding : utf-8 -*-

require 'spec_helper'
require 'guacamole/model'
require 'guacamole/collection'

class TestModel
  include Guacamole::Model
end

class OtherModel
  include Guacamole::Model
end

describe Guacamole::Model do
  subject { TestModel }
  let(:current_time) { Time.now }
  let(:callbacks) { double('Callback') }
  let(:callbacks_module) { double('CallbacksModule') }

  before do
    allow(callbacks_module).to receive(:callbacks_for).and_return(callbacks)
    allow(callbacks).to receive(:run_callbacks).with(:validate).and_yield
    stub_const('Guacamole::Callbacks', callbacks_module)
  end

  describe 'module inclusion' do
    it 'should include Virtus.model' do
      expect(subject.ancestors.any? do |ancestor|
        ancestor.to_s.include? 'Virtus'
      end).to be true
    end

    it 'should include ActiveModel::Validation' do
      expect(subject.ancestors).to include ActiveModel::Validations
    end

    it 'should include ActiveModel::Naming' do
      expect(subject.ancestors).to include ActiveModel::Naming
    end

    it 'should include ActiveModel::Conversion' do
      expect(subject.ancestors).to include ActiveModel::Conversion
    end
  end

  describe 'default attributes' do
    subject { TestModel.new }

    it 'should add the key attribute' do
      subject.key = '12345'
      expect(subject.key).to eq '12345'
    end

    it 'should add the rev attribute' do
      subject.rev = '98765'
      expect(subject.rev).to eq '98765'
    end

    it 'should add the created_at attribute' do
      subject.created_at = current_time
      expect(subject.created_at).to be current_time
    end

    it 'should add the updated_at attribute' do
      subject.updated_at = current_time
      expect(subject.updated_at).to be current_time
    end
  end

  describe 'persisted?' do
    subject { TestModel.new }

    it 'should be persisted if it has a key' do
      subject.key = 'my_key'
      expect(subject.persisted?).to be true
    end

    it "should not be persisted if it doesn't have a key" do
      subject.key = nil
      expect(subject.persisted?).to be false
    end
  end

  describe 'callbacks' do
    subject { TestModel.new }

    it 'should register one callback class responsible for this model' do
      awesome_callbacks_class = double('AwesomeCallbacksClass')
      stub_const('AwesomeCallbacks', awesome_callbacks_class)
      expect(callbacks_module).to receive(:register_callback).with(TestModel, awesome_callbacks_class)

      TestModel.callbacks :awesome_callbacks
    end

    it 'should run validate callbacks on valid?' do
      expect(callbacks).to receive(:run_callbacks).with(:validate).and_yield
      expect(subject).to receive(:valid_without_callbacks?)

      subject.valid?
    end

    it 'should provide method to get callback for self' do
      expect(callbacks_module).to receive(:callbacks_for).with(subject)

      subject.callbacks
    end
  end

  describe 'id' do
    subject { TestModel.new }

    it 'should alias key to id for ActiveModel::Conversion compliance' do
      subject.key = 'my_key'
      expect(subject.id).to eq 'my_key'
    end
  end

  describe 'arangodb_id' do
    let(:model_key) { double('Key') }
    let(:collection_name) { double('CollectionName') }

    subject { TestModel.new }

    before do
      allow(subject).to receive(:key).and_return(model_key)
      allow(subject).to receive(:collection_name).and_return(collection_name)
    end

    context 'with persisted model' do
      before do
        allow(subject).to receive(:persisted?).and_return(true)
      end

      its(:arangodb_id) { should eq [collection_name, model_key].join('/') }
    end

    context 'with non-persisted model' do
      before do
        allow(subject).to receive(:persisted?).and_return(false)
      end

      its(:arangodb_id) { should be_nil }
    end
  end

  describe 'collection_name' do
    let(:default_mapper) { class_double('Guacamole::DocumentModelMapper') }
    let(:configuration) { instance_double('Guacamole::Configuration') }
    let(:collection) { double('Guacamole::Collection') }
    let(:collection_name) { double('CollectionName') }

    subject { TestModel.new }

    before do
      allow(Guacamole).to receive(:configuration).and_return(configuration)
      allow(configuration).to receive(:default_mapper).and_return(default_mapper)
      allow(default_mapper).to receive(:collection_for).with(subject.class).and_return(collection)
      allow(collection).to receive(:collection_name).and_return(collection_name)
    end

    its(:collection_name) { should eq collection_name }
  end

  describe '==' do
    let(:key) { double('Key') }
    let(:rev) { double('Rev') }
    let(:updated_at) { Time.now }
    let(:content) { double('String') }
    let(:unixy_time) { 1_445_444_940 } # If you read this line and understand it, you get a beer
    let(:timestamp_without_nsecs) { Time.at(unixy_time, 0) }
    let(:timestamp_with_nsecs) { Time.at(unixy_time, 42) }

    subject { TestModel.new(key: key, rev: rev, updated_at: updated_at, content: content) }
    let(:comparison_object) { TestModel.new(subject.attributes) }

    it 'should not be equal if it is a different class' do
      expect(subject).to_not eq double
    end

    it 'should be equal if all attributes are equal' do
      expect(subject).to eq comparison_object
    end

    it 'should be equal if the time is equal in string representation' do
      subject.updated_at = timestamp_with_nsecs
      comparison_object.updated_at = timestamp_without_nsecs

      expect(subject).to eq comparison_object
    end

    it 'should alias `eql?` to `==`' do
      expect(subject).to eql comparison_object
    end
  end
end
