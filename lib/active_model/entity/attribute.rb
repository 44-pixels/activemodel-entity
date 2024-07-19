# frozen_string_literal: true

# Patch for ActiveModel::Type::Value to support casting JSON values
ActiveModel::Type::Value.class_eval do
  # Add alias to `cast` method for casting JSON values in ActiveModel::Attribute::FromJSON class
  alias_method :cast_json, :cast
end

module ActiveModel
  # Patch for ActiveModel::Attribute to support from_json
  class Attribute
    class << self
      def from_json(name, value_before_type_cast, type, original_attribute = nil)
        FromJSON.new(name, value_before_type_cast, type, original_attribute)
      end
    end

    def with_value_from_json(value)
      type.assert_valid_value(value)
      self.class.from_json(name, value, type, original_attribute || self)
    end

    # Almost identical to the original `FromUser` class, but with a different `type_cast` method
    class FromJSON < Attribute
      def type_cast(value)
        type.cast_json(value)
      end

      def came_from_user?
        !type.value_constructed_by_mass_assignment?(value_before_type_cast)
      end

      private

      def _value_for_database
        ActiveModel::Type::SerializeCastValue.serialize(type, value)
      end
    end

    private_constant :FromJSON
  end
end
