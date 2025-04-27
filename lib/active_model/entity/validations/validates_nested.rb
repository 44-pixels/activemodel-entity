# frozen_string_literal: true

module ActiveModel
  module Entity
    module Validations
      # A handy concern that allows to say that all child entities should be validated together with parent
      #
      module ValidatesNested
        extend ActiveSupport::Concern

        class_methods do
          def validates_nested
            attribute_types.filter_map do |name, type|
              name if type.is_a?(ActiveModel::Entity::Type::Array) || type.is_a?(ActiveModel::Entity::Type::Entity)
            end => attribute_to_validate

            attribute_to_validate.each do |attr_name|
              validates attr_name, nested_entity: true
            end
          end
        end
      end
    end
  end
end
