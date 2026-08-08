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

            # Values read off one of our own instances were already cast by these exact
            # types, so +serialize_cast_value+ is valid for them and skips the redundant
            # re-casting work +serialize+ would redo on every field. Anything else --
            # a Hash, an ActiveRecord model, an OpenStruct -- carries values this class
            # never cast, so it keeps the full +serialize+ path.
            build_representation(object_or_hash, options, entity_options, object_or_hash.instance_of?(self))
          end

          # Default options for representing an entity.
          # Override this method to provide custom default options for Entity
          #
          # Frozen so that Ruby 3.4+ (opt_hash_freeze) hands back the same object every
          # call instead of allocating one. Every nested entity calls this once, so a
          # large payload was allocating a hash per nested object just to read :camelize.
          def default_represent_options
            { camelize: true }.freeze
          end

          private

          # +pre_cast+ says whether the source's values already went through these types.
          # +serialize_cast_value+ is a no-op for +nil+ on every compatible type, so no
          # nil guard is needed here.
          def build_representation(source, options, entity_options, pre_cast)
            represent_plan(entity_options[:camelize]).each_with_object({}) do |(json_name, name, type, custom_serializer, cast_value_serializable), memo|
              value = custom_serializer ? custom_serializer.call(source, entity_options) : fetch_field_value(source, name)

              memo[json_name] = if pre_cast && cast_value_serializable
                                  type.serialize_cast_value(value)
                                else
                                  type.serialize_with_options(value, options)
                                end
            end
          end

          # Compiled once per exact class (class-level ivars are not inherited) and
          # per camelization mode: one
          # [json_name, name, type, custom_serializer, cast_value_serializable] tuple per
          # attribute, so name camelization, serializer lookups and the
          # serialize_cast_value compatibility check happen once instead of on every
          # +represent+ call.
          def represent_plan(camelize)
            plans = (@represent_plans ||= {})

            plans[camelize ? :camelized : :plain] ||= attribute_types.map do |name, type|
              json_name = camelize ? name.camelcase(:lower) : name
              custom_serializer = custom_serializers[name]

              [json_name, name, type, custom_serializer, !custom_serializer && cast_value_serializable?(type)]
            end
          end

          # Whether +type+ opted into ActiveModel's "this value was already cast by me"
          # protocol. Resolved once at plan-compile time; +SerializeCastValue.serialize+
          # answers the same question but re-derives it (behind a +rescue+) per value.
          # Nested :entity/:array types are not compatible and keep recursing normally.
          def cast_value_serializable?(type)
            type.respond_to?(:itself_if_serialize_cast_value_compatible) &&
              type.equal?(type.itself_if_serialize_cast_value_compatible)
          end
        end
      end
    end
  end
end
