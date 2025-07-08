# frozen_string_literal: true

# This file is only loaded when explicitly required or when Rails/ActiveJob is present
# It provides ActiveJob serialization support for ActiveModel::Entity objects

if defined?(ActiveJob)
  module ActiveJob
    module Serializers
      # Handles serialization of all ActiveModel::Entity classes.
      class ActiveModelSerializer < ActiveJob::Serializers::ObjectSerializer
        def serialize?(argument)
          argument.is_a?(ActiveModel::Entity)
        end

        def serialize(argument)
          super(
            "type" => argument.class.name,
            "json" => argument.class.represent(argument),
          )
        end

        def deserialize(hash)
          hash["type"].constantize.from_json(hash["json"])
        end
      end
    end
  end
end
