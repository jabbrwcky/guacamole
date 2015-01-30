# -*- encoding : utf-8 -*-

require 'ashikawa-core'

module Guacamole
  class Transaction
    attr_reader :collection, :model

    # A simple structure to build the vertex information we need to pass to the
    # transaction code.
    class Vertex < Struct.new(:model, :collection, :document)
      # The key of the wrapped model
      #
      # @return [String] The key of the model
      def key
        model.key
      end

      # The id of the wrapped model
      #
      # If the model was never saved and thus don't have an id yet we will
      # return Model#object_id instead.
      #
      # @return [String] The id of the model
      def id
        model._id || model.object_id
      end

      # Creates a hash to be used in the transaction
      #
      # @return [Hash] A hash with the required information to be passed to the database
      def as_json
        {
         object_id: model.object_id,
         collection: collection,
         document: document,
         _key: key,
         _id: id
        }
      end
    end

    class TargetStatesBuilder
      class << self
        def build(model, collection)
          if collection.mapper.edge_attributes.empty?
            [VertexTargetState.new(model, collection)]
          else
            collection.mapper.edge_attributes.map { |edge_attribute| SubGraphTargetState.new(model, edge_attribute) }
          end
        end
      end
    end

    class VertexTargetState
      attr_reader :model, :collection

      def initialize(model, collection)
        @model      = model
        @collection = collection
      end

      def vertex
        Vertex.new(model,
                   collection.collection_name,
                   collection.mapper.model_to_document(model))
      end

      def edge_collection_name
        nil
      end

      def as_json
        {
         name: nil,
         fromVertices: [vertex],
         toVertices: [],
         edges: [],
         oldEdges: []
        }
      end
    end

    class SubGraphTargetState
      attr_reader :start_model, :edge_attribute

      def initialize(model, edge_attribute)
        @edge_attribute = edge_attribute
        @start_model    = model
      end

      def edge_class
        edge_attribute.edge_class
      end

      def edge_collection
        EdgeCollection.for(edge_class)
      end

      def edge_collection_name
        edge_collection.collection_name
      end

      def mapper_for_model(model)
        edge_collection.mapper_for_start(model)
      end

      def model_to_document(model)
        mapper_for_model(model).model_to_document(model)
      end

      def related_models
        [edge_attribute.get_value(start_model)].compact.flatten
      end

      def old_edge_keys
        case start_model
        when edge_class.from_collection.model_class
          edge_collection.by_example(_from: start_model._id).map(&:key)
        when edge_class.to_collection.model_class
          edge_collection.by_example(_to: start_model._id).map(&:key)
        end
      end

      def from_vertices
        case start_model
        when edge_class.from_collection.model_class
          [Vertex.new(start_model, edge_class.from_collection.collection_name, model_to_document(start_model))]
        when edge_class.to_collection.model_class
          related_models.map { |from_model| Vertex.new(from_model, edge_class.from_collection.collection_name, model_to_document(from_model)) }
        end
      end

      def all_to_vertices
        case start_model
        when edge_class.from_collection.model_class
          related_models.map { |to_model| Vertex.new(to_model, edge_class.to_collection.collection_name, model_to_document(to_model)) }
        when edge_class.to_collection.model_class
           [Vertex.new(start_model, edge_class.to_collection.collection_name, model_to_document(start_model))]
        end
      end

      def to_vertices
        all_to_vertices.reject(&:key)
      end

      def edges
        from_vertices.product(to_vertices).map do |from_vertex, to_vertex|
          { _from: from_vertex.id, _to: to_vertex.id, attributes: {} }
        end
      end

      def as_json
        {
          name: edge_collection_name,
          fromVertices: from_vertices,
          toVertices: to_vertices_with_only_existing_documents,
          edges: edges,
          oldEdges: old_edge_keys
        }
      end
    end

    class << self
      def run(options)
        new(options).execute_transaction
      end
    end

    def initialize(options)
      @collection = options[:collection]
      @model      = options[:model]
      init_connection_to_database
    end

    def edge_collections
      TargetStatesBuilder.build(model, collection)
    end

    def write_collections
      edge_collections.flat_map do |target_state|
        [target_state.edge_collection_name] +
          (target_state.from_vertices + target_state.to_vertices).map(&:collection)
      end.uniq.compact
    end

    def read_collections
      write_collections
    end

    def transaction_params
      {
        edgeCollections: edge_collections,
        graph: Guacamole.configuration.graph.name,
        log_level: 'debug'
      }
    end

    def execute_transaction
      transaction.execute(transaction_params)
    end

    def transaction_code
      File.read(Guacamole.configuration.shared_path.join('transaction.js'))
    end

    def transaction
      transaction = database.create_transaction(transaction_code,
                                                write: write_collections,
                                                read:  read_collections)
      transaction.wait_for_sync = true

      transaction
    end

    private

    def database
      collection.database
    end

    # Requests the collection from the database
    #
    # If the collection was not existing before this will create it.
    # If the collection already exists, this will be a no-op
    def init_connection_to_database
      @collection.connection
    end
  end
end
