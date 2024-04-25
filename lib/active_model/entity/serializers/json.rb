# frozen_string_literal: true

module ActiveModel
  module Entity
    module Serializers
      module JSON
        extend ActiveSupport::Concern

        module ClassMethods
          def fetch_field_value(object_or_hash, name)
            if object_or_hash.is_a?(Hash)
              object_or_hash[name]
            else
              object_or_hash.send(name)
            end
          end

          def represent(object_or_hash, camelize: true)
            object_or_hash = object_or_hash.with_indifferent_access if object_or_hash.is_a?(Hash)

            self.attribute_types.each_with_object({}) do |(name, type), memo|
              json_name = name.camelcase(:lower) if camelize
              value = fetch_field_value(object_or_hash, name)
              memo[json_name] = type.serialize(value)
            end
          end
        end
      end
    end
  end
end