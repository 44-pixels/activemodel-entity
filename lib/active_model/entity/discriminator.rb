# frozen_string_literal: true

module ActiveModel
  module Entity
    # STI-style unions: a base entity names a tag attribute and a closed mapping of tag => subclass.
    #
    #   class ThreadContext
    #     include ActiveModel::Entity
    #
    #     discriminated_by :type, admin: "ThreadContext::Admin", whatsapp: "ThreadContext::Whatsapp"
    #   end
    #
    # Going through the base (+new+, +from_json+, +represent+) dispatches on the tag; a subclass
    # carries its tag as the attribute's default and validates it. The base's JSON schema is a
    # +oneOf+ of the subclasses with an OpenAPI +discriminator+.
    module Discriminator
      extend ActiveSupport::Concern

      included do
        class_attribute :discriminator, instance_accessor: false
      end

      # The tag attribute, the mapping and the base that declared them. Mapping values may be
      # class names of classes defined later, so they are only constantized on first use.
      class Definition
        attr_reader :base, :attribute, :mapping

        def initialize(base, attribute, mapping)
          @base = base
          @attribute = attribute.to_s
          @mapping = mapping.transform_keys(&:to_s).freeze
        end

        def classes
          @classes ||= mapping.transform_values { _1.is_a?(Class) ? _1 : _1.to_s.constantize }
        end

        def tag_for(klass)
          classes.key(klass)
        end

        def resolve(tag)
          raise ArgumentError, "#{base}: missing #{attribute} tag, expected one of #{tags_list}" if tag.nil?

          classes.fetch(tag.to_s) { raise ArgumentError, "#{base}: unknown #{attribute} tag #{tag.inspect}, expected one of #{tags_list}" }
        end

        private

        def tags_list
          mapping.keys.map(&:inspect).join(", ")
        end
      end

      # Class-level methods.
      module ClassMethods
        def discriminated_by(name, mapping)
          attribute(name, :string) unless attribute_types.key?(name.to_s)
          self.discriminator = Definition.new(self, name, mapping)
          validate :validate_discriminator_tag
          descendants.each { define_discriminator_default(_1) }
        end

        # The tag this class is mapped under, nil for the base and for unmapped subclasses.
        def discriminator_tag
          return @discriminator_tag if defined?(@discriminator_tag)

          @discriminator_tag = discriminator&.tag_for(self)
        end

        def discriminated_base?
          discriminator&.base.equal?(self)
        end

        def inherited(subclass)
          super

          define_discriminator_default(subclass) if discriminator
        end

        # Without attributes the base itself is built, which is what +from_json+ starts from.
        def new(*args, **kwargs, &)
          target = discriminator_target(args.first || kwargs.presence, discriminator&.attribute)
          target.equal?(self) ? super : target.new(*args, **kwargs, &)
        end

        def from_json(json)
          target = discriminator_target(json, discriminator&.attribute&.camelize(:lower))
          target.equal?(self) ? super : target.from_json(json)
        end

        def represent(object_or_hash, options = {})
          return super unless discriminated_base?

          target = object_or_hash.is_a?(self) ? object_or_hash.class : discriminator.resolve(fetch_field_value(object_or_hash, discriminator.attribute))
          target.equal?(self) ? super : target.represent(object_or_hash, options)
        end

        def represent_all(sources, options = {})
          return super unless discriminated_base?

          sources.map { _1.nil? ? nil : represent(_1, options) }
        end

        def as_json_schema(inline: false)
          return union_json_schema(inline:) if discriminated_base?

          schema = super
          tag = discriminator_tag
          return schema unless tag

          name = discriminator.attribute.camelize(:lower)
          schema[:properties][name][:enum] = [tag]
          schema[:required] |= [name]
          schema
        end

        private

        def define_discriminator_default(subclass)
          subclass.attribute(discriminator.attribute, default: -> { subclass.discriminator_tag })
        end

        # The class a source hash builds: self unless this is a discriminated base, in which
        # case the tag under +key+ (string or symbol) picks the subclass.
        def discriminator_target(source, key)
          return self unless discriminated_base? && source

          tag = source[key]
          tag = source[key.to_sym] if tag.nil?
          discriminator.resolve(tag)
        end

        def union_json_schema(inline:)
          definition = discriminator
          refs = definition.classes.transform_values(&:json_schema_ref)
          one_of = inline ? definition.classes.values.map { _1.as_json_schema(inline:) } : refs.values.map { { "$ref": _1 } }
          discriminator_schema = { propertyName: definition.attribute.camelize(:lower) }
          discriminator_schema[:mapping] = refs unless inline

          { oneOf: one_of, discriminator: discriminator_schema, description: meta_descriptions[nil].first }.compact
        end
      end

      private

      def validate_discriminator_tag
        definition = self.class.discriminator
        value = public_send(definition.attribute)
        return if (tag = self.class.discriminator_tag) && value == tag

        errors.add(definition.attribute.to_sym, :inclusion, value:)
      end
    end
  end
end
