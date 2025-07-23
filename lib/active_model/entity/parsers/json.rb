# frozen_string_literal: true

module ActiveModel
  module Entity
    module Parsers
      # Provides helper routines allowing creating ActiveModel::Entity instances from a JSON object.
      module JSON
        extend ActiveSupport::Concern

        def set_attribute_from_json(name, value)
          original_attribute_name = attribute_aliases.fetch(name, name)
          @attributes[original_attribute_name] = @attributes[original_attribute_name].with_value_from_json(value)
        end

        # Class-level methods.
        module ClassMethods
          def from_json(json)
            unified_json = json.stringify_keys
            new.tap do |instance|
              instance.camelized_attributes_names.each do |name|
                next unless unified_json.key?(name)

                instance.set_attribute_from_json(name, unified_json[name])
              end
            end
          end
        end
      end
    end
  end
end
