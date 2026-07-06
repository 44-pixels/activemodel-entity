# frozen_string_literal: true

module ActiveModel
  module Entity
    module Parsers
      # Provides helper routines allowing creating ActiveModel::Entity instances from a JSON object.
      module JSON
        extend ActiveSupport::Concern

        def set_attribute_from_json(name, value)
          @attributes[name] = @attributes[name].with_value_from_json(value)
        end

        def assign_attributes_from_json(json)
          instance_exec(json, &self.class.json_attributes_assigner)
        end

        # Class-level methods.
        module ClassMethods
          def from_json(json)
            new.tap do |instance|
              instance.assign_attributes_from_json(json)
            end
          end

          # Compiled once per exact class (class-level ivars are not
          # inherited), so an assigner compiled for a superclass can never
          # shadow attributes that exist only on a subclass.
          def json_attributes_assigner
            @json_attributes_assigner ||= compile_json_attributes_assigner
          end

          private

          def compile_json_attributes_assigner
            setters = attribute_types.keys.map do |name|
              <<~RUBY
                #{name}_value = json[#{name.camelize(:lower).inspect}]
                #{name}_value = json[#{name.camelize(:lower).to_sym.inspect}] if #{name}_value.nil?

                set_attribute_from_json(
                  #{name.inspect},
                  #{name}_value
                )
              RUBY
            end

            code = <<~RUBY
              ->(json) do
                #{setters.join("\n")}
              end
            RUBY

            class_eval(code, __FILE__, __LINE__)
          end
        end
      end
    end
  end
end
