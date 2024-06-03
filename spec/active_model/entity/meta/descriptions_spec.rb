# frozen_string_literal: true

require "ostruct"

module DescriptionsTest
  class Base
    include ActiveModel::Entity
  end

  class Role < Base
    desc "This is my class"

    desc "This is my attribute"
    attribute :field_name, :string

    desc "This is my other attribute"
    attribute :other_field_name, :string
  end

  class RandomClass < Base
  end

  class SubRole < Base
    desc "This is my OTHER class"

    desc "This is my OTHER attribute"
    attribute :some_field_name, :string
  end
end

RSpec.describe ActiveModel::Entity::Meta::Descriptions do
  it "works" do
    schema = DescriptionsTest::Role.as_json_schema

    properties = { "fieldName" => { type: :string, description: "This is my attribute" },
                   "otherFieldName" => { type: :string, description: "This is my other attribute" } }

    expect(schema).to eq({ type: :object,
                           description: "This is my class",
                           required: %w[],
                           properties: })
  end

  context "BE-47 leaking meta information to subclasses" do
    it "BE-47 does not leak descriptions" do
      schema = DescriptionsTest::RandomClass.as_json_schema

      expect(schema).to eq({ type: :object,
                             required: %w[],
                             properties: {} })
    end

    it "does inherit and override metas" do
      schema = DescriptionsTest::SubRole.as_json_schema

      properties = { "someFieldName" => { type: :string, description: "This is my OTHER attribute" } }

      expect(schema).to eq({ type: :object,
                             description: "This is my OTHER class",
                             required: %w[],
                             properties: })
    end
  end
end
