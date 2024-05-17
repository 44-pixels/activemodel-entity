# frozen_string_literal: true

require "ostruct"

module SerializersTest
  class Role
    include ActiveModel::Entity
    attribute :field_name, :string
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
    attribute :field_role, :entity, class_name: "SerializersTest::Role"
    attribute :field_roles, :array, of: "SerializersTest::Role"
    attribute :field_integers, :array, of: :integer
  end
end

RSpec.describe ActiveModel::Entity::Serializers::JSON do
  context "representing a hash" do
    let(:source) do
      {
        field_obj: { x: 1 },
        field_big_integer: 137,
        field_boolean: false,
        field_date: Date.new(2024, 1, 1),
        field_datetime: DateTime.new(2024, 1, 1, 1, 3, 7),
        field_float: 1.37,
        field_integer: 138,
        field_string: "string",
        field_time: Time.new(2024, 1, 1, 1, 3, 8),
        field_role: { field_name: "nom" },
        field_roles: [{ field_name: "prenom" }],
        field_integers: [1, 3, 7]
      }
    end

    it "represents as JSON" do
      json = SerializersTest::Person.represent(source)

      expect(json.deep_symbolize_keys).to eq({
        fieldObj: { x: 1 },
        fieldBigInteger: 137,
        fieldBoolean: false,
        fieldDate: Date.new(2024, 1, 1),
        fieldDatetime: DateTime.new(2024, 1, 1, 1, 3, 7),
        fieldFloat: 1.37,
        fieldInteger: 138,
        fieldString: "string",
        fieldTime: Time.new(2024, 1, 1, 1, 3, 8),
        fieldRole: { fieldName: "nom" },
        fieldRoles: [{ fieldName: "prenom" }],
        fieldIntegers: [1, 3, 7]
      })
    end
  end

  context "representing an object" do
    let(:source) do
      OpenStruct.new({
        field_obj: { x: 1 },
        field_big_integer: 137,
        field_boolean: false,
        field_date: Date.new(2024, 1, 1),
        field_datetime: DateTime.new(2024, 1, 1, 1, 3, 7),
        field_float: 1.37,
        field_integer: 138,
        field_string: "string",
        field_time: Time.new(2024, 1, 1, 1, 3, 8),
        field_role: OpenStruct.new({ field_name: "nom" }),
        field_roles: [OpenStruct.new({ field_name: "prenom" })],
        field_integers: [1, 3, 7]
      })
    end

    it "represents as JSON" do
      json = SerializersTest::Person.represent(source)

      expect(json.deep_symbolize_keys).to eq({
        fieldObj: { x: 1 },
        fieldBigInteger: 137,
        fieldBoolean: false,
        fieldDate: Date.new(2024, 1, 1),
        fieldDatetime: DateTime.new(2024, 1, 1, 1, 3, 7),
        fieldFloat: 1.37,
        fieldInteger: 138,
        fieldString: "string",
        fieldTime: Time.new(2024, 1, 1, 1, 3, 8),
        fieldRole: { fieldName: "nom" },
        fieldRoles: [{ fieldName: "prenom" }],
        fieldIntegers: [1, 3, 7]
      })
    end
  end
end
