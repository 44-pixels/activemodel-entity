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
          # @param block [Proc] The block to use for serialization. Object or hash and options are passed as arguments.
          def serializes(attribute, &block)
            custom_serializers[attribute.to_s] = block
            @represent_plans = nil
          end

          # Invalidate the compiled represent plans when a new attribute is defined.
          def attribute(...)
            @represent_plans = nil
            super
          end

          def fetch_field_value(object_or_hash, name)
            if object_or_hash.is_a?(Hash)
              value = object_or_hash[name]
              value.nil? ? object_or_hash[name.to_sym] : value
            else
              object_or_hash.send(name)
            end
          end

          def represent(object_or_hash, options = {})
            entity_options = options.empty? ? default_represent_options : default_represent_options.merge(options)

            # Custom serializer blocks receive the source hash itself and may look fields
            # up by string or symbol, so they keep getting an indifferent-access copy.
            object_or_hash = object_or_hash.with_indifferent_access if custom_serializers.any? && object_or_hash.is_a?(Hash)

            represent_plan(entity_options[:camelize]).each_with_object({}) do |(json_name, name, type, custom_serializer), memo|
              value = custom_serializer ? custom_serializer.call(object_or_hash, entity_options) : fetch_field_value(object_or_hash, name)

              memo[json_name] = type.serialize_with_options(value, options)
            end
          end

          # Default options for representing an entity.
          # Override this method to provide custom default options for Entity
          def default_represent_options
            { camelize: true }
          end

          private

          # Compiled once per exact class (class-level ivars are not inherited) and
          # per camelization mode: one [json_name, name, type, custom_serializer]
          # tuple per attribute, so name camelization and serializer lookups happen
          # once instead of on every +represent+ call.
          def represent_plan(camelize)
            plans = (@represent_plans ||= {})

            plans[camelize ? :camelized : :plain] ||= attribute_types.map do |name, type|
              json_name = camelize ? name.camelcase(:lower) : name

              [json_name, name, type, custom_serializers[name]]
            end
          end
        end
      end
    end
  end
end
