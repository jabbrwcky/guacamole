# -*- encoding : utf-8 -*-

require 'guacamole/collection'
require 'guacamole/aql_query'

require 'ashikawa-core'
require 'active_support'
require 'active_support/concern'
require 'active_support/core_ext/string/inflections'

module Guacamole
  module EdgeCollection
    extend ActiveSupport::Concern
    include Guacamole::Collection

    NEIGHBORS_AQL_STRING = <<-AQL
      FOR n IN GRAPH_NEIGHBORS(@graph,
                      { _key: @model_key },
                      { direction: @direction, edgeCollectionRestriction: @edge_collection })
        RETURN { "vertex" : n.vertex, "edge_attributes" : ZIP(ATTRIBUTES(n.path.edges[0],true,false), VALUES(n.path.edges[0], true))}
    AQL

    class AnnotatedEdgeMapper
      def initialize(model_mapper, model_class)
        @model_mapper = model_mapper
        @model_class = model_class
      end

      Container = Struct.new(:edge_attributes, :model)
      def document_to_model(document)
        Container.new(document['edge_attributes'], @model_mapper.hash_to_model(document['vertex']))
      end

      def model_class
        @model_class
      end
    end

    class << self
      def for(edge_class)
        collection_name = [edge_class.name.pluralize, 'Collection'].join
        collection_name.constantize
      rescue NameError
        create_edge_collection(collection_name)
      end

      def create_edge_collection(qualified_collection_name)
        hierarchy = qualified_collection_name.split('::')
        collection_name = hierarchy.last
        mod=Object

        unless hierarchy.length == 1
          hierarchy[0..-2].each do |m|
            begin
              mod = mod.const_get(m, false)
            rescue NameError
              mod = mod.class_eval{const_set(m, Module.new)}
            end
          end
        end

        new_collection_class = Class.new
        mod.const_set(collection_name, new_collection_class)
        new_collection_class.send(:include, Guacamole::EdgeCollection)
      end
    end

    module ClassMethods
      def connection
        @connection ||= graph.edge_collection(collection_name)
      end

      def edge_class
        @edge_class ||= model_class
      end

      def add_edge_definition_to_graph
        graph.add_edge_definition(collection_name,
                                  from: [edge_class.from.to_s.gsub('/','__')],
                                  to: [edge_class.to.to_s.gsub('/','__')])
      end

      def neighbors(model, direction = :inbound)
        query                 = AqlQuery.new(self, AnnotatedEdgeMapper.new(mapper_for_target(model), model.class), return_as: nil, for_in: nil)
        query.aql_fragment    = NEIGHBORS_AQL_STRING
        query.bind_parameters = build_bind_parameter(model, direction)
        query
      end

      def build_bind_parameter(model, direction = :inbound)
        {
          graph: Guacamole.configuration.graph.name,
          model_key: model.key,
          edge_collection: collection_name,
          direction: direction
        }
      end

      def mapper_for_target(model)
        vertex_mapper.find { |mapper| !mapper.responsible_for?(model) }
      end

      def mapper_for_start(model)
        vertex_mapper.find { |mapper| mapper.responsible_for?(model) }
      end

      def vertex_mapper
        [edge_class.from_collection, edge_class.to_collection].map(&:mapper)
      end
    end

    included do
      add_edge_definition_to_graph
    end
  end
end
