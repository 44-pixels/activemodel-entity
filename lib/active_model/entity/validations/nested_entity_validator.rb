# frozen_string_literal: true

module ActiveModel
  module Entity
    module Validations
      # It allows for the validation of nested entities within a parent entity.
      #
      class NestedEntityValidator < ActiveModel::EachValidator
        def validate_each(record, attribute, value)
          Array.wrap(value).each_with_index do |entity, index|
            next if !entity.respond_to?(:valid?) || entity.valid?

            entity.errors.messages.each do |attr, message|
              record.errors.add(attribute, "Error in nested entity ##{index} for #{attr}: #{message}")
            end
          end
        end
      end
    end
  end
end
