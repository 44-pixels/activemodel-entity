# frozen_string_literal: true

module ActiveModel
  module Entity
    module Meta
      # Provides helper routines allowing ActiveModel::Entity to specify descriptions on the attributes and the entity.
      module Descriptions
        extend ActiveSupport::Concern

        included do
          class_attribute :meta_descriptions, default: {}
        end

        # Class-level methods.
        module ClassMethods
          # Specifies the description for the next defined attribute.
          # If the call to ::desc is followed by another call, the first one becomes class description.
          def desc(comment)
            meta_descriptions[nil] ||= []
            meta_descriptions[nil] << comment
          end

          # Intercepts calls to ::attribute method updating meta_descriptions dictionary.
          def attribute(name, ...)
            pending_comments = meta_descriptions[nil] || []
            last_comment = pending_comments.pop

            meta_descriptions[name.to_sym] = last_comment if last_comment
            super
          end
        end
      end
    end
  end
end
