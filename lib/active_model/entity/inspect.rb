# frozen_string_literal: true

module ActiveModel
  module Entity
    # Adds a custom inspect method to the entity
    module Inspect
      extend ActiveSupport::Concern

      def inspect
        "#<#{self.class} #{as_json}>"
      end
    end
  end
end
