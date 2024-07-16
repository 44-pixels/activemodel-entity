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
          def from_json(json)
            new.tap do |instance|
              instance.attributes.each_key do |key|
                field_key = key.camelize(:lower)

                instance.set_attribute_from_json(key, json[field_key])
              end
            end
          end
        end
      end
    end
  end
end
