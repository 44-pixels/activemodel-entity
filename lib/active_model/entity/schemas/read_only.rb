# frozen_string_literal: true

module ActiveModel
  module Entity
    module Schemas
      # Tracks attributes declared with `read_only: true` and derives the request-variant
      # schemas that those attributes imply for this entity and everything it references.
      module ReadOnly
        extend ActiveSupport::Concern

        included do
          class_attribute :read_only_attributes, default: [].freeze, instance_accessor: false
        end

        # Class-level methods.
        module ClassMethods
          # Intercepts ::attribute, consuming `read_only:` before ActiveModel forwards options to Type.lookup.
          def attribute(name, *, read_only: false, **)
            self.read_only_attributes = (read_only_attributes + [name.to_s]).freeze if read_only

            super(name, *, **)
          end

          # Entity classes this one references through attributes that survive into a variant.
          # Read-only attributes are excluded: a variant never emits them, so it never refs their target.
          def nested_entity_types
            attribute_types.except(*read_only_attributes).each_value.filter_map do |type|
              type = type.element_type if type.is_a?(Type::Array)
              type.entity_type if type.is_a?(Type::Entity)
            end
          end

          # True when this entity, or anything reachable from it, declares a read-only attribute.
          # ponytail: recomputed per call rather than memoized — memoizing an in-progress node as
          # false is a real false negative on cycles, and the graph is dozens of tiny classes.
          def read_only_subtree?(seen = [])
            return false if seen.include?(self)

            seen << self
            read_only_attributes.any? || nested_entity_types.any? { _1.read_only_subtree?(seen) }
          end

          # Every variant component transitively referenced by this entity, keyed by component id.
          def json_schema_variants(variant = :request, acc = {})
            return acc unless read_only_subtree?

            id = json_schema_id(variant)
            return acc if acc.key?(id)

            acc[id] = as_json_schema(variant:)
            nested_entity_types.each { _1.json_schema_variants(variant, acc) }
            acc
          end
        end
      end
    end
  end
end
