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
          VARIANT_SUFFIXES = { request: "-Request" }.freeze

          # A hyphen is used deliberately: it cannot appear in a Ruby constant path, so a variant id
          # can never collide with the id of a real inner class in the flat components/schemas namespace.
          def json_schema_id(variant = nil)
            base = name.gsub("::", ".")
            return base if variant.nil?

            suffix = VARIANT_SUFFIXES.fetch(variant)
            read_only_subtree? ? "#{base}#{suffix}" : base
          end

          def json_schema_ref(variant = nil)
            "#/components/schemas/#{json_schema_id(variant)}"
          end

          def required_attributes
            presence_validators = validators.group_by(&:class)[ActiveModel::Validations::PresenceValidator].to_a
            presence_validators = presence_validators.reject { _1.options[:required] == false }
            presence_validators.flat_map(&:attributes).to_a
          end

          def nullable_attributes
            presence_validators = validators.group_by(&:class)[ActiveModel::Validations::PresenceValidator].to_a
            presence_validators = presence_validators.select { _1.options[:allow_nil] }
            presence_validators.flat_map(&:attributes).to_a
          end

          def enum_attributes
            inclusion_validators = validators.group_by(&:class)[ActiveModel::Validations::InclusionValidator].to_a
            inclusion_validators.select { _1.options[:in] }

            inclusion_validators.each_with_object({}) do |validator, result|
              validator.attributes.each do |name|
                result[name.to_s] = validator.options[:in]
              end
            end
          end

          def primitive_type_schema(type)
            return { type: :object } if type.type.nil?
            return { type: :number } if NUMBER_TYPES.include?(type.type)
            return { type: :string } if STRING_TYPES.include?(type.type)
            return { type: :boolean } if BOOLEAN_TYPES.include?(type.type)

            nil
          end

          def entity_schema_for(type, inline, variant)
            inline ? type.entity_type.as_json_schema(inline:, variant:) : { "$ref": type.entity_type.json_schema_ref(variant) }
          end

          def array_schema_for(type, inline, variant)
            { items: json_schema_attribute_for(type.element_type, inline:, variant:), type: :array }
          end

          def json_schema_attribute_for(type, inline: false, variant: nil)
            schema = primitive_type_schema(type)
            return schema if schema

            return entity_schema_for(type, inline, variant) if type.is_a?(Type::Entity)
            return array_schema_for(type, inline, variant) if type.is_a?(Type::Array)

            raise NotImplementedError
          end

          def make_schema_nullable!(options)
            options[:allOf] = ["$ref": options.delete(:$ref)] if options[:$ref].present?

            options[:nullable] = true
          end

          def append_description_if_available!(name, options)
            key = name.underscore.to_sym
            options[:description] = meta_descriptions[key] if meta_descriptions.key?(key)
          end

          # Mirrors ::make_schema_nullable!: an OpenAPI 3.0 sibling of $ref is ignored, so wrap first.
          def append_read_only_if_declared!(names, name, options)
            return unless names.include?(name)

            options[:allOf] = ["$ref": options.delete(:$ref)] if options[:$ref].present?
            options[:readOnly] = true
          end

          def append_enum!(values, options, type)
            target = type.is_a?(Type::Array) ? options[:items] : options
            target[:enum] = values
          end

          # Property names a variant omits. Fetches the suffix purely to validate eagerly: otherwise
          # a typo'd variant silently strips every read-only property on an entity with no nested
          # $ref to route the check through.
          def hidden_attribute_names(variant)
            return [] if variant.nil?

            VARIANT_SUFFIXES.fetch(variant)
            read_only_attributes.map { _1.camelize(:lower) }
          end

          def as_json_schema(inline: false, variant: nil)
            type = :object
            description = meta_descriptions[nil].first
            read_only = read_only_attributes.map { _1.camelize(:lower) }
            hidden = hidden_attribute_names(variant)
            required = required_attributes.map(&:name).map { _1.camelize(:lower) } - hidden
            nullable = nullable_attributes.map(&:name).index_by { _1.camelize(:lower) }

            attributes = attribute_types.transform_keys { _1.camelize(:lower) }.except(*hidden)
            properties = attributes.transform_values { json_schema_attribute_for(_1, inline:, variant:) }
            enums = enum_attributes.transform_keys { _1.camelize(:lower) }

            properties.each do |name, options|
              make_schema_nullable!(options) if nullable.key?(name)
              append_description_if_available!(name, options)
              append_enum!(enums[name], options, attributes[name]) if enums.key?(name)
              append_read_only_if_declared!(read_only, name, options)
            end

            { type:, description:, required:, properties: }.compact
          end
        end
      end
    end
  end
end
