# frozen_string_literal: true

module ActiveModel
  module Entity
    # Adds equality between entities
    module Equality
      extend ActiveSupport::Concern

      def eql?(other)
        attributes.as_json.eql?(other.attributes.as_json)
      end

      def ==(other)
        eql?(other)
      end

      def hash
        [self.class, *attributes.keys, *attributes.values].hash
      end
    end
  end
end
