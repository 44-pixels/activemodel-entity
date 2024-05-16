# frozen_string_literal: true

require "ostruct"

module SchemasTest
  class Role
    include ActiveModel::Entity
    attribute :field_name, :string
  end

  class Person
    include ActiveModel::Entity

    # attribute :field_obj
    attribute :field_big_integer, :big_integer
    attribute :field_boolean, :boolean
    attribute :field_date, :date
    attribute :field_datetime, :datetime
    attribute :field_float, :float
    attribute :field_integer, :integer
    attribute :field_string, :string
    attribute :field_time, :time
    attribute :field_role, :entity, class_name: "SchemasTest::Role"
    attribute :field_roles, :array, of: "SchemasTest::Role"
    attribute :field_integers, :array, of: :integer
    attribute :field_without_type

    validates :field_boolean, presence: true
    validates :field_float, presence: true
  end
end

RSpec.describe ActiveModel::Entity::Schemas::JSON do
  it "works" do
    schema = SchemasTest::Person.as_json_schema
    expect(schema).to eq({ type: :object,
                           required: %w[fieldBoolean fieldFloat],
                           properties: { "fieldBigInteger" => { type: :number },
                                         "fieldBoolean" => { type: :boolean },
                                         "fieldDate" => { type: :string },
                                         "fieldDatetime" => { type: :string },
                                         "fieldFloat" => { type: :number },
                                         "fieldInteger" => { type: :number },
                                         "fieldString" => { type: :string },
                                         "fieldTime" => { type: :string },
                                         "fieldRole" => { :$ref => "#/components/schemas/SchemasTest.Role" },
                                         "fieldRoles" => { items: { :$ref => "#/components/schemas/SchemasTest.Role" }, type: :array },
                                         "fieldIntegers" => { items: { type: :number }, type: :array },
                                         "fieldWithoutType" => { type: :object } } })
  end
end
