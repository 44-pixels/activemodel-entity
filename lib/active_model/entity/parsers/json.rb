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

        # Class-level methods.
        module ClassMethods
          def from_json(json)
            new.tap do |instance|
              instance.assign_attributes_from_json(json)
            end
          end
        end

        def method_missing(method_name, *, &)
          if method_name == :assign_attributes_from_json
            setters = attributes.keys.map do |name|
              <<~RUBY
                #{name}_value = json[#{name.camelize(:lower).inspect}]
                #{name}_value = json[#{name.camelize(:lower).to_sym.inspect}] if #{name}_value.nil?

                self.set_attribute_from_json(
                  #{name.inspect},
                  #{name}_value
                )
              RUBY
            end

            code = <<~RUBY
              def assign_attributes_from_json(json)
                #{setters.join("\n")}
              end
            RUBY

            self.class.class_eval(code)
            send(method_name, *, &)
          else
            super
          end
        end

        def respond_to_missing?(method_name, include_private)
          method_name == :assign_attributes_from_json || super
        end
      end
    end
  end
end
