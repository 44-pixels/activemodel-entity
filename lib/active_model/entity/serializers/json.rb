# frozen_string_literal: true

module ActiveModel
  module Entity
    module Serializers
      # Provides helper routines allowing for representing arbitrary values as JSON.
      module JSON
        extend ActiveSupport::Concern

        included do
          class_attribute :custom_serializers, default: {}
        end

        # Class-level methods.
        module ClassMethods
          # Handle inheritance by clonning custom_serializers value
          def inherited(subclass)
            super

            subclass.custom_serializers = custom_serializers.dup
          end

          #
          # Specifies custom serialization for attribute.
          # @param attribute [Symbol|String] The attribute to serialize.
          # @param callable [Proc] The callable to use for serialization. Object or hash and options are passed as arguments.
          def serialization(attribute, callable)
            custom_serializers[attribute.to_s] = callable
          end

          def fetch_field_value(object_or_hash, name)
            if object_or_hash.is_a?(Hash)
              object_or_hash[name]
            else
              object_or_hash.send(name)
            end
          end

          def represent(object_or_hash, options = {})
            entity_options = default_represent_options.merge(options)

            camelize = entity_options[:camelize]

            object_or_hash = object_or_hash.with_indifferent_access if object_or_hash.is_a?(Hash)

            attribute_types.each_with_object({}) do |(name, type), memo|
              json_name = camelize ? name.camelcase(:lower) : name

              custom_serializer = custom_serializers[name]

              value = if custom_serializer.present?
                        custom_serializer.call(object_or_hash, entity_options)
                      else
                        fetch_field_value(object_or_hash, name)
                      end

              memo[json_name] = type.serialize_with_options(value, options)
            end
          end

          # Default options for representing an entity.
          # Override this method to provide custom default options for Entity
          def default_represent_options
            { camelize: true }
          end
        end
      end
    end
  end
end
