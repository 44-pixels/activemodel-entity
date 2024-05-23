# frozen_string_literal: true

require "ostruct"

module DescriptionsTest
  class Role
    include ActiveModel::Entity

    desc "This is my class"

    desc "This is my attribute"
    attribute :field_name, :string

    desc "This is my other attribute"
    attribute :other_field_name, :string
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
end
