# frozen_string_literal: true

require "ostruct"

module SchemasTest
  class Role
    include ActiveModel::Entity
    attribute :field_name, :string
  end

  class Person
    include ActiveModel::Entity

    attribute :field_big_integer, :big_integer
    attribute :field_boolean, :boolean
    attribute :field_date, :date
    attribute :field_datetime, :datetime
    attribute :field_float, :float
    attribute :field_integer, :integer
    attribute :field_string, :string
    attribute :field_time, :time
    attribute :field_role, :entity, class_name: "SchemasTest::Role"
    attribute :field_nullable_role, :entity, class_name: "SchemasTest::Role"
    attribute :field_nullable_not_required_role, :entity, class_name: "SchemasTest::Role"
    attribute :field_roles, :array, of: "SchemasTest::Role"
    attribute :field_integers, :array, of: :integer
    attribute :field_without_type
    attribute :field_nullable_string, :string
    attribute :field_nullable_not_required_string, :string
    attribute :field_enum_string, :string
    attribute :field_enum_int, :integer

    validates :field_boolean, presence: true
    validates :field_float, presence: true
    validates :field_nullable_string, presence: { allow_nil: true }
    validates :field_nullable_not_required_string, presence: { allow_nil: true, required: false }
    validates :field_nullable_role, presence: { allow_nil: true }
    validates :field_nullable_not_required_role, presence: { allow_nil: true, required: false }
    validates :field_enum_string, inclusion: { in: %w[an enum] }
    validates :field_enum_int, inclusion: { in: [1, 3, 7] }
  end
end

RSpec.describe ActiveModel::Entity::Schemas::JSON do
  it "works" do
    schema = SchemasTest::Person.as_json_schema

    properties = { "fieldBigInteger" => { type: :number },
                   "fieldBoolean" => { type: :boolean },
                   "fieldDate" => { type: :string },
                   "fieldDatetime" => { type: :string },
                   "fieldFloat" => { type: :number },
                   "fieldInteger" => { type: :number },
                   "fieldString" => { type: :string },
                   "fieldTime" => { type: :string },
                   "fieldRole" => { :$ref => "#/components/schemas/SchemasTest.Role" },
                   "fieldNullableRole" => { :$ref => "#/components/schemas/SchemasTest.Role", nullable: true },
                   "fieldNullableNotRequiredRole" => { :$ref => "#/components/schemas/SchemasTest.Role", nullable: true },
                   "fieldRoles" => { items: { :$ref => "#/components/schemas/SchemasTest.Role" }, type: :array },
                   "fieldIntegers" => { items: { type: :number }, type: :array },
                   "fieldNullableString" => { type: :string, nullable: true },
                   "fieldNullableNotRequiredString" => { type: :string, nullable: true },
                   "fieldWithoutType" => { type: :object },
                   "fieldEnumString" => { type: :string, enum: %w[an enum] },
                   "fieldEnumInt" => { type: :number, enum: [1, 3, 7] } }

    expect(schema).to eq({
      type: :object,
      required: %w[fieldBoolean fieldFloat fieldNullableString fieldNullableRole],
      properties:
    })
  end
end
