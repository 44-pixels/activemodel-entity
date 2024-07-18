# frozen_string_literal: true

require "ostruct"

module ParsersTest
  class Position
    include ActiveModel::Entity

    attribute :field_name, :string
  end

  class Role
    include ActiveModel::Entity

    attribute :field_name, :string
    attribute :field_position, :entity, class_name: "ParsersTest::Position"
    attribute :field_positions, :array, of: "ParsersTest::Position"
  end

  class Person
    include ActiveModel::Entity

    attribute :field_obj
    attribute :field_big_integer, :big_integer
    attribute :field_boolean, :boolean
    attribute :field_date, :date
    attribute :field_datetime, :datetime
    attribute :field_float, :float
    attribute :field_integer, :integer
    attribute :field_string, :string
    attribute :field_time, :time
    attribute :field_role, :entity, class_name: "ParsersTest::Role"
    attribute :field_roles, :array, of: "ParsersTest::Role"
    attribute :field_integers, :array, of: :integer
  end
end

RSpec.describe ActiveModel::Entity::Parsers::JSON do
  context "parsing ActionController::Parameters" do
    let(:source) do
      ActionController::Parameters.new({
        fieldObj: { x: 1 },
        fieldBigInteger: 137,
        fieldBoolean: false,
        fieldDate: "2024-01-01",
        fieldDatetime: "2024-01-01T01:03:07",
        fieldFloat: 1.37,
        fieldInteger: 138,
        fieldString: "string",
        fieldTime: "2024-02-03T01:03:08",
        fieldRole: { fieldName: "nom", fieldNotMapped: "not_mapped", fieldPosition: { fieldName: "ceo" } },
        fieldRoles: [{ fieldName: "prenom", fieldPositions: [{ fieldName: "cpo" }] }],
        fieldIntegers: [1, 3, 7],
        fieldNotMapped: "not_mapped"
      })
    end

    it "loads an object" do
      person = ParsersTest::Person.from_json(source)

      expect(person).to be_valid
      expect(person.as_json.deep_symbolize_keys).to eq({
        field_obj: { x: 1 },
        field_big_integer: 137,
        field_boolean: false,
        field_date: "2024-01-01",
        field_datetime: "2024-01-01T01:03:07.000Z",
        field_float: 1.37,
        field_integer: 138,
        field_string: "string",
        field_time: "2000-01-01T01:03:08.000Z",
        field_role: { field_name: "nom", field_position: { field_name: "ceo" }, field_positions: nil },
        field_roles: [{ field_name: "prenom", field_position: nil, field_positions: [{ field_name: "cpo" }] }],
        field_integers: [1, 3, 7]
      })
    end
  end

  context "parsing json" do
    let(:source) do
      {
        fieldObj: { x: 1 },
        fieldBigInteger: 137,
        fieldBoolean: false,
        fieldDate: "2024-01-01",
        fieldDatetime: "2024-01-01T01:03:07",
        fieldFloat: 1.37,
        fieldInteger: 138,
        fieldString: "string",
        fieldTime: "2024-02-03T01:03:08",
        fieldRole: { fieldName: "nom", fieldNotMapped: "not_mapped", fieldPosition: { fieldName: "ceo" } },
        fieldRoles: [{ fieldName: "prenom", fieldPositions: [{ fieldName: "cpo" }] }],
        fieldIntegers: [1, 3, 7],
        fieldNotMapped: "not_mapped"
      }
    end

    it "loads an object" do
      person = ParsersTest::Person.from_json(source.deep_stringify_keys)

      expect(person).to be_valid
      expect(person.as_json.deep_symbolize_keys).to eq({
        field_obj: { x: 1 },
        field_big_integer: 137,
        field_boolean: false,
        field_date: "2024-01-01",
        field_datetime: "2024-01-01T01:03:07.000Z",
        field_float: 1.37,
        field_integer: 138,
        field_string: "string",
        field_time: "2000-01-01T01:03:08.000Z",
        field_role: { field_name: "nom", field_position: { field_name: "ceo" }, field_positions: nil },
        field_roles: [{ field_name: "prenom", field_position: nil, field_positions: [{ field_name: "cpo" }] }],
        field_integers: [1, 3, 7]
      })
    end
  end
end
