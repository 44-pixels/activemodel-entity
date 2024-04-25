# frozen_string_literal: true

require_relative "lib/active_model/entity/version"

Gem::Specification.new do |spec|
  spec.name = "activemodel-entity"
  spec.version = ActiveModel::Entity::VERSION
  spec.authors = ["Anton Zhuravsky"]
  spec.email = ["anton@44pixels.ai"]

  spec.summary = "Make ActiveModel be like Pydantic"
  spec.description = "Extends ActiveModel modules with support for collections, JSON schema generation, parsing and represenations"
  spec.homepage = "https://github.com/44-pixels/activemodel-entity"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/44-pixels/activemodel-entity"

  spec.require_paths = Dir["LICENSE.txt", "README.md", "lib/**/*"]

  # Uncomment to register a new dependency of your gem
  spec.add_dependency "activesupport", ">= 7"
  spec.add_dependency "activemodel", ">= 7"
end
