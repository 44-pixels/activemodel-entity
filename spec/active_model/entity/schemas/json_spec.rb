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
    attribute :field_enum_string_array, :array, of: :string

    validates :field_boolean, presence: true
    validates :field_float, presence: true
    validates :field_nullable_string, presence: { allow_nil: true }
    validates :field_nullable_not_required_string, presence: { allow_nil: true, required: false }
    validates :field_nullable_role, presence: { allow_nil: true }
    validates :field_nullable_not_required_role, presence: { allow_nil: true, required: false }
    validates :field_enum_string, inclusion: { in: %w[an enum] }
    validates :field_enum_int, inclusion: { in: [1, 3, 7] }
    validates :field_enum_string_array, inclusion: { in: %w[an enum] }
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
                   "fieldNullableRole" => { allOf: [:$ref => "#/components/schemas/SchemasTest.Role"], nullable: true },
                   "fieldNullableNotRequiredRole" => { allOf: [:$ref => "#/components/schemas/SchemasTest.Role"], nullable: true },
                   "fieldRoles" => { items: { :$ref => "#/components/schemas/SchemasTest.Role" }, type: :array },
                   "fieldIntegers" => { items: { type: :number }, type: :array },
                   "fieldNullableString" => { type: :string, nullable: true },
                   "fieldNullableNotRequiredString" => { type: :string, nullable: true },
                   "fieldWithoutType" => { type: :object },
                   "fieldEnumString" => { type: :string, enum: %w[an enum] },
                   "fieldEnumInt" => { type: :number, enum: [1, 3, 7] },
                   "fieldEnumStringArray" => { type: :array, items: { type: :string, enum: %w[an enum] } } }

    expect(schema).to eq({
      type: :object,
      required: %w[fieldBoolean fieldFloat fieldNullableString fieldNullableRole],
      properties:
    })
  end

  context "with inline: true" do
    it "inlines nested entity schemas" do
      schema = SchemasTest::Person.as_json_schema(inline: true)

      expect(schema[:properties]["fieldRole"]).to eq({
        type: :object,
        required: [],
        properties: { "fieldName" => { type: :string } }
      })
    end

    it "inlines array of entity schemas" do
      schema = SchemasTest::Person.as_json_schema(inline: true)

      expect(schema[:properties]["fieldRoles"]).to eq({
        type: :array,
        items: {
          type: :object,
          required: [],
          properties: { "fieldName" => { type: :string } }
        }
      })
    end

    it "preserves nullable flag on inlined entities" do
      schema = SchemasTest::Person.as_json_schema(inline: true)

      expect(schema[:properties]["fieldNullableRole"]).to eq({
        type: :object,
        required: [],
        properties: { "fieldName" => { type: :string } },
        nullable: true
      })
    end

    it "keeps primitive types unchanged" do
      schema = SchemasTest::Person.as_json_schema(inline: true)

      expect(schema[:properties]["fieldString"]).to eq({ type: :string })
      expect(schema[:properties]["fieldInteger"]).to eq({ type: :number })
      expect(schema[:properties]["fieldBoolean"]).to eq({ type: :boolean })
    end

    it "keeps array of primitives unchanged" do
      schema = SchemasTest::Person.as_json_schema(inline: true)

      expect(schema[:properties]["fieldIntegers"]).to eq({
        type: :array,
        items: { type: :number }
      })
    end

    it "keeps enum on items for array of enums" do
      schema = SchemasTest::Person.as_json_schema(inline: true)

      expect(schema[:properties]["fieldEnumStringArray"]).to eq({
        type: :array,
        items: { type: :string, enum: %w[an enum] }
      })
    end
  end

  describe "validation of arrays of enums" do
    let(:entity) { SchemasTest::Person.new(field_boolean: true, field_float: 1.0, field_nullable_string: "x") }

    it "is valid when all elements are in the allowed set" do
      entity.field_enum_string_array = %w[an enum]
      entity.valid?
      expect(entity.errors[:field_enum_string_array]).to be_empty
    end

    it "is invalid when any element is not in the allowed set" do
      entity.field_enum_string_array = %w[an other]
      entity.valid?
      expect(entity.errors[:field_enum_string_array]).not_to be_empty
    end

    it "is valid when the array is empty" do
      entity.field_enum_string_array = []
      entity.valid?
      expect(entity.errors[:field_enum_string_array]).to be_empty
    end
  end
end
