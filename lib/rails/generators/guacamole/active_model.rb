module Guacamole
  module Generators
    # This class implements Guacamole specifics to generate controller code
    #
    # Since Guacamole implements a data mapper pattern and Rails expects an
    # interface similar to ActiveRecord this implementation is a bit hacky.
    # Additionally it was required to customize the template itself.
    #
    # @see https://github.com/rails/rails/blob/master/railties/lib/rails/generators/active_model.rb
    class ActiveModel
      attr_reader :name

      def initialize(name)
        @name = name
      end

      # GET index
      def self.all(klass)
        "#{klass.pluralize}Collection.all"
      end

      # GET show
      # GET edit
      # PATCH/PUT update
      # DELETE destroy
      def self.find(klass, params=nil)
        "#{klass.pluralize}Collection.by_key(#{params})"
      end

      # GET new
      # POST create
      def self.build(klass, params=nil)
        if params
          "#{klass}.new(#{params})"
        else
          "#{klass}.new"
        end
      end

      # POST create
      def save
        "#{collection_class}.save(#{model_instance})"
      end

      # PATCH/PUT update
      def update(params=nil)
        "#{collection_class}.save(#{params})"
      end

      # POST create
      # PATCH/PUT update
      def errors
        "#{name}.errors"
      end

      # DELETE destroy
      def destroy
        "#{collection_class}.delete(#{model_instance})"
      end

      private

      def collection_class
        "#{name.camelize.pluralize}Collection"
      end

      def model_instance
        "@#{name}"
      end
    end
  end
end
