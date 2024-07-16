# frozen_string_literal: true

module ActiveModel
  module Entity
    module Parsers
      # Provides helper routines allowing creating ActiveModel::Entity instances from a JSON object.
      module JSON
        extend ActiveSupport::Concern

        def set_attribute_from_json(name, value)
          @attributes[name] = @attributes[name].with_value_from_user(value)
        end

        # Class-level methods.
        module ClassMethods
          def from_json(json, underscore: true)
            new.tap do |instance|
              entity_attributes = instance.attributes.keys
              entity_attributes.map!(&:underscore) if underscore

              json.each do |key, value|
                key = key.to_s.underscore if underscore

                # Skip unknown attributes.
                next unless entity_attributes.include?(key)

                # FIXME: underscore is not passed down to nested parsers!
                instance.set_attribute_from_json(key, value)
              end
            end
          end
        end
      end
    end
  end
end
