# frozen_string_literal: true
require "active_support/all"
require "active_model"

require_relative "entity/version"
require_relative "entity/type"
require_relative "entity/parsers/json"


module ActiveModel
  module Entity
    extend ActiveSupport::Concern

    included do
      include ActiveModel::Attributes
      include ActiveModel::Serializers::JSON
      include ActiveModel::API
      include ActiveModel::Entity::Parsers::JSON
    end
  end
end
