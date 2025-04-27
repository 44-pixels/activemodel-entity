# frozen_string_literal: true

module ActiveModel
  module Entity
    # Makes entities pattern matchable
    #
    module PatternMatcheable
      # Copied from here:
      # https://github.com/kddnewton/rails-pattern_matching/blob/main/lib/rails/pattern_matching.rb#L149
      def deconstruct_keys(keys)
        if keys
          # If we've been given keys, then we're going to filter down to just the
          # attributes that were given for this object.
          keys.each_with_object({}) do |key, deconstructed|
            string_key = key.to_s

            # If the user provided a key that doesn't match an attribute, then we
            # do not add it to the result hash, and the match will fail.
            deconstructed[key] = public_send(string_key) if attribute_method?(string_key)
          end
        else
          # If we haven't been given keys, then the user wants to grab up all of the
          # attributes for this object.
          attributes.transform_keys(&:to_sym)
        end
      end
    end
  end
end
