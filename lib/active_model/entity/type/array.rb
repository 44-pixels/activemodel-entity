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

        def serialize(value)
          return nil if value.nil?

          value.map { element_type.serialize(_1) }
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
