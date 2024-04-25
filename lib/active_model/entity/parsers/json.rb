# frozen_string_literal: true

module ActiveModel
  module Entity
    module Parsers
      module JSON
        extend ActiveSupport::Concern

        def set_attribute_from_json(name, value)
          @attributes[name] = @attributes[name].with_value_from_user(value)
        end

        module ClassMethods
          def from_json(json, underscore: true)
            new.tap do |instance|
              json.each do |key, value|
                key = key.to_s.underscore if underscore
                instance.set_attribute_from_json(key, value)
              end
            end
          end
        end
      end
    end
  end
end