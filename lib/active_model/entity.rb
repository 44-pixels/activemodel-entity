# frozen_string_literal: true

require "active_support/all"
require "active_model"
require "action_controller/metal/strong_parameters"

require_relative "entity/attribute"
require_relative "entity/version"
require_relative "entity/type"
require_relative "entity/parsers/json"
require_relative "entity/serializers/json"
require_relative "entity/schemas/json"
require_relative "entity/meta/descriptions"
require_relative "entity/equality"
require_relative "entity/inspect"
require_relative "entity/validations/nested_entity_validator"
require_relative "entity/validations/exclusive_presence_validator"
require_relative "entity/validations/validates_nested"
require_relative "entity/pattern_matcheable"

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
      include ActiveModel::Entity::Meta::Descriptions
      include ActiveModel::Entity::Equality
      include ActiveModel::Entity::Inspect
      include ActiveModel::Entity::Validations
      include ActiveModel::Entity::Validations::ValidatesNested
      include ActiveModel::Entity::PatternMatcheable
    end
  end
end
