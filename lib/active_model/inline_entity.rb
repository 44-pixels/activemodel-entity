# frozen_string_literal: true

module ActiveModel
  # Provides a simple way to define inline entities
  #
  class InlineEntity
    # A configuration object to define the attributes of the entity
    #
    class Config
      include Enumerable

      def initialize
        @attributes = {}
      end

      def each(&)
        @attributes.each(&)
      end

      def method_missing(attribute_name, type = nil, **validations, &block)
        @attributes[attribute_name] = { type:, validations: DEFAULT_VALIDATIONS.merge(validations), block: }
      end

      def respond_to_missing?(_attribute_name, _include_private = false)
        true
      end
    end

    DEFAULT_VALIDATIONS = { presence: true }.freeze
    NESTED_ENTITY_TYPES = %i[entity array].freeze

    def self.define(klass_name = "", &)
      config = Config.new
      config.instance_eval(&)
      entity = new(config)
      entity.compile(klass_name)
    end

    def initialize(config)
      @config = config
    end

    def compile(namespaced_klass_name)
      entity_klass = build_entity_klass(namespaced_klass_name)

      @config.each do |name, options|
        next define_nested_entity_attribute(entity_klass, name, options) if NESTED_ENTITY_TYPES.include?(options[:type])

        entity_klass.attribute name, options[:type]

        entity_klass.validates name, **options[:validations] if options[:validations].length.positive?
      end

      entity_klass
    end

    private

    def define_nested_entity_attribute(parent_entity_klass, name, options)
      nested_entity_klass = ::ActiveModel::InlineEntity.define("#{parent_entity_klass.name}::#{name.to_s.camelize}", &options[:block])

      case options[:type]
      when :entity
        parent_entity_klass.attribute name, :entity, class_name: nested_entity_klass.name
      when :array
        parent_entity_klass.attribute name, :array, of: nested_entity_klass.name
      end
    end

    def build_entity_klass(namespaced_klass_name)
      entity = Class.new.include(ActiveModel::Entity)
      if namespaced_klass_name.include?("::")
        namespaced_klass_name.split("::")
      else
        [nil, namespaced_klass_name]
      end => string_namespace, klass_name

      namespace = string_namespace ? string_namespace.constantize : Object

      full_class_name = "#{klass_name}InlineEntity"
      namespace.const_set(full_class_name, entity)

      "#{namespace.name}::#{full_class_name}".constantize
    end
  end
end
