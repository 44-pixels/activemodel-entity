# frozen_string_literal: true

require 'active_model/type'

require_relative 'type/entity'
require_relative 'type/array'

module ActiveModel
  module Entity
    module Type
      ::ActiveModel::Type.register(:entity, Type::Entity)
      ::ActiveModel::Type.register(:array, Type::Array)
    end
  end
end
