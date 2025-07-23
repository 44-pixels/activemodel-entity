# frozen_string_literal: true

module ActiveModel
  module Entity
    # Adds alias for attribute with camelcase name
    module CamelCaseable
      extend ActiveSupport::Concern

      included do
        class_attribute :camelized_attributes_names, default: []
      end

      module ClassMethods
        def attribute(name, ...)
          super

          camelize_name = name.to_s.camelize(:lower)
          camelized_attributes_names.push(camelize_name)

          return unless name.to_s != camelize_name

            alias_attribute camelize_name.to_sym, name
        end
      end
    end
  end
end
