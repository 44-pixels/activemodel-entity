# frozen_string_literal: true

module ActiveModel
  module Entity
    module Validations
      # It allows to validate that exactly one of the specified attributes is present in the record.
      #
      class ExclusivePresenceValidator < ActiveModel::Validator
        def validate(record)
          attributes = options[:fields] || []
          present_count = attributes.count { |attr| record.send(attr).present? }
          return if present_count == 1

          record.errors.add(:base, "Exactly one of #{attributes.join(", ")} must be present")
        end
      end
    end
  end
end
