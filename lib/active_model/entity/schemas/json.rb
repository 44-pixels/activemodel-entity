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

          def as_json_schema
            type = :object
            required = required_attributes.map(&:name).map { _1.camelize(:lower) }

            attributes = attribute_types.transform_keys { _1.camelize(:lower) }
            properties = attributes.transform_values { json_schema_attribute_for(_1) }

            { type:, required:, properties: }
          end
        end
      end
    end
  end
end
