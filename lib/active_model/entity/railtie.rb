# frozen_string_literal: true

module ActiveModel
  module Entity
    # Railtie to integrate with Rails and ActiveJob
    class Railtie < Rails::Railtie
      initializer "activemodel_entity.configure_active_job_serializer" do
        require "active_model/entity/active_job"

        if defined?(ActiveJob::Serializers::ActiveModelSerializer)
          Rails.application.config.to_prepare do
            Rails.application.config.active_job.custom_serializers << ActiveJob::Serializers::ActiveModelSerializer
          end
        end
      end
    end
  end
end
