# frozen_string_literal: true

module ActiveModel
  module Entity
    module Type
      # Attribute type for associated model's representation. It is registered under the
      # +:entity+ key.
      #
      #   class Role
      #     include ActiveModel::Attributes
      #   end
      #
      #   class Person
      #     include ActiveModel::Attributes
      #
      #     attribute :role, :model, class_name: 'Role'
      #   end
      #
      #   person = Person.new
      #   person.role = Role.new
      #
      #   person.role.class # => Role
      #
      class Entity < ::ActiveModel::Type::Value
        attr_reader :class_name

        def initialize(class_name: nil)
          super()
          @class_name = class_name
        end

        def type
          :entity
        end

        def type_cast_for_schema(value)
          raise NotImplementedError
        end

        def serialize(value)
          return nil if value.nil?

          entity_type.represent(value)
        end

        def entity_type
          @entity_type ||= class_name.constantize
        end

        def cast_json(value)
          return nil if value.nil?
          return value if value.is_a?(entity_type)
          return entity_type.from_json(value) if value.is_a?(Hash)
          return entity_type.from_json(value) if value.is_a?(ActionController::Parameters)

          raise NotImplementedError
        end

        private

        def cast_value(value)
          return nil if value.nil?
          return value if value.is_a?(entity_type)
          return entity_type.new(value) if value.is_a?(Hash)
          return entity_type.new(value) if value.is_a?(ActionController::Parameters)

          raise NotImplementedError
        end
      end
    end
  end
end
