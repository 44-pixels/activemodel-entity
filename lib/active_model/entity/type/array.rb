# frozen_string_literal: true

module ActiveModel
  module Entity
    module Type
      # Attribute type for arrays representation. It is registered under the
      # +:array+ key.
      #
      #   class Role
      #     include ActiveModel::Attributes
      #   end
      #
      #   class Person
      #     include ActiveModel::Attributes
      #
      #     attribute :roles, :array, of: 'Role'
      #     attribute :names, :array, of: :string
      #   end
      #
      #   person = Person.new
      #   person.roles = [Role.new]
      #   person.names = ['ivan', 'vanya']
      #
      #   person.roles.class # => Array
      #   person.names.class # => Array
      #
      class Array < ::ActiveModel::Type::Value
        attr_reader :element_type_name

        def initialize(of: nil)
          super()
          @element_type_name = of
        end

        def type
          :array
        end

        def type_cast_for_schema(value)
          raise NotImplementedError
        end

        # Fallback for direct calls
        def serialize(value)
          serialize_with_options(value)
        end

        # Seriaze Array by serializing each element with options
        def serialize_with_options(value, options = {})
          return nil if value.nil?

          element = element_type

          # An array of entities resolves the represent plan and options once for the
          # whole collection instead of once per element. The check is deliberately on
          # the exact class: a Type::Entity subclass may override serialize_with_options,
          # and routing around it would silently change behaviour.
          return element.entity_type.represent_all(value, options) if element.instance_of?(::ActiveModel::Entity::Type::Entity)

          value.map { element.serialize_with_options(_1, options) }
        end

        def element_type
          @element_type ||= if element_type_name.is_a?(String)
                              ::ActiveModel::Entity::Type::Entity.new(class_name: element_type_name)
                            else
                              ::ActiveModel::Type.lookup(element_type_name)
                            end
        end

        def cast_json(value)
          return nil if value.nil?
          raise NotImplementedError unless value.is_a?(::Array)

          value.map { |entry| element_type.cast_json(entry) }
        end

        private

        def cast_value(value)
          return nil if value.nil?
          raise NotImplementedError unless value.is_a?(::Array)

          value.map { |entry| element_type.cast(entry) }
        end
      end
    end
  end
end
