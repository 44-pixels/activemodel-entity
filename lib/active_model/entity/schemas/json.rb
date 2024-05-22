# frozen_string_literal: true

module ActiveModel
  module Entity
    module Schemas
      # Provides helper routines allowing JSON schema generation for an entity.
      module JSON
        extend ActiveSupport::Concern

        # Class-level methods.
        module ClassMethods
          NUMBER_TYPES = %i[big_integer decimal float integer].freeze
          STRING_TYPES = %i[string immutable_string date datetime time].freeze
          BOOLEAN_TYPES = %i[boolean].freeze

          def json_schema_id
            name.gsub("::", ".")
          end

          def json_schema_ref
            "#/components/schemas/#{json_schema_id}"
          end

          def required_attributes
            presence_validators = validators.group_by(&:class)[ActiveModel::Validations::PresenceValidator].to_a
            presence_validators = presence_validators.reject { _1.options[:allow_nil] }
            presence_validators.flat_map(&:attributes).to_a
          end

          def nullable_attributes
            presence_validators = validators.group_by(&:class)[ActiveModel::Validations::PresenceValidator].to_a
            presence_validators = presence_validators.select { _1.options[:allow_nil] }
            presence_validators.flat_map(&:attributes).to_a
          end

          def json_schema_attribute_for(type)
            return { type: :object } if type.type.nil?
            return { type: :number } if NUMBER_TYPES.include?(type.type)
            return { type: :string } if STRING_TYPES.include?(type.type)
            return { type: :boolean } if BOOLEAN_TYPES.include?(type.type)
            return { "$ref": type.entity_type.json_schema_ref } if type.is_a?(Type::Entity)
            return { items: json_schema_attribute_for(type.element_type), type: :array } if type.is_a?(Type::Array)

            raise NotImplementedError
          end

          def make_schema_nullable!(options)
            options[:type] = [options[:type], :null] if options[:type]
            options[:nullable] = true if options[:$ref]
          end

          def append_description_if_available!(name, options)
            key = name.underscore.to_sym
            options[:description] = meta_descriptions[key] if meta_descriptions.key?(key)
          end

          def as_json_schema
            type = :object
            description = (meta_descriptions[nil] || []).first
            required = required_attributes.map(&:name).map { _1.camelize(:lower) }
            nullable = nullable_attributes.map(&:name).index_by { _1.camelize(:lower) }

            attributes = attribute_types.transform_keys { _1.camelize(:lower) }
            properties = attributes.transform_values { json_schema_attribute_for(_1) }

            properties.each do |name, options|
              make_schema_nullable!(options) if nullable.key?(name)
              append_description_if_available!(name, options)
            end

            { type:, description:, required:, properties: }.reject { _2.nil? }
          end
        end
      end
    end
  end
end
