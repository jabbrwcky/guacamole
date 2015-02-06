# -*- encoding: utf-8 -*-

require 'guacamole/proxies/proxy'
require 'guacamole/edge_collection'

module Guacamole
  module Proxies
    # This class smells of :reek:TooManyInstanceVariables
    class Relation < Proxy
      # This method smells of :reek:TooManyStatements
      def initialize(model, edge_class, options = {})
        @model      = model
        @edge_class = edge_class
        @options    = options

        @target = lambda do
          neighbors = edge_collection.neighbors(@model, direction)
          relates_to_collection? ? neighbors : neighbors.to_a.first
        end
      end

      def edge_collection
        EdgeCollection.for(@edge_class)
      end

      def direction
        @options[:inverse] ? :inbound : :outbound
      end

      def relates_to_collection?
        !@options[:just_one]
      end
    end
  end
end
