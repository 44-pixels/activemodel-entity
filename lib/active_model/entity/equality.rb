# frozen_string_literal: true

module ActiveModel
  module Entity
    # Adds equality between entities
    module Equality
      extend ActiveSupport::Concern

      def eql?(other)
        attributes.eql?(other.attributes)
      end

      def ==(other)
        eql?(other)
      end

      def hash
        [self.class, *attributes.keys, *attributes.keys].hash
      end
    end
  end
end
