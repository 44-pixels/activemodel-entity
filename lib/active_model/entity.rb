# frozen_string_literal: true

require "active_support/all"
require "active_model"
require "action_controller/metal/strong_parameters"

require_relative "entity/version"
require_relative "entity/type"
require_relative "entity/parsers/json"
require_relative "entity/serializers/json"
require_relative "entity/schemas/json"

module ActiveModel
  # Main module providing all neccesary includes to bring missing functionality to ActiveModel instances.
  module Entity
    extend ActiveSupport::Concern

    included do
      include ActiveModel::API
      include ActiveModel::Attributes
      include ActiveModel::Serializers::JSON
      include ActiveModel::Entity::Parsers::JSON
      include ActiveModel::Entity::Serializers::JSON
      include ActiveModel::Entity::Schemas::JSON
    end
  end
end
