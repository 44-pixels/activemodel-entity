# frozen_string_literal: true

module EqualityTest
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
    attribute :field_role, :entity, class_name: "EqualityTest::Role"
    attribute :field_roles, :array, of: "EqualityTest::Role"
    attribute :field_integers, :array, of: :integer
  end
end

RSpec.describe ActiveModel::Entity::Equality do
  let(:person) do
    EqualityTest::Person.new(
      field_obj: { x: 1 },
      field_big_integer: 137,
      field_boolean: false,
      field_date: Date.new(2024, 1, 1),
      field_datetime: DateTime.new(2024, 1, 1, 1, 3, 7),
      field_float: 1.37,
      field_integer: 138,
      field_string: "string",
      field_time: Time.new(2024, 1, 1, 1, 3, 8, "UTC"),
      field_role: EqualityTest::Role.new(field_name: "nom"),
      field_roles: [EqualityTest::Role.new(field_name: "prenom")],
      field_integers: [1, 3, 7]
    )
  end

  let(:same_person) do
    EqualityTest::Person.new(
      field_obj: { x: 1 },
      field_big_integer: 137,
      field_boolean: false,
      field_date: Date.new(2024, 1, 1),
      field_datetime: DateTime.new(2024, 1, 1, 1, 3, 7),
      field_float: 1.37,
      field_integer: 138,
      field_string: "string",
      field_time: Time.new(2024, 1, 1, 1, 3, 8, "UTC"),
      field_role: EqualityTest::Role.new(field_name: "nom"),
      field_roles: [EqualityTest::Role.new(field_name: "prenom")],
      field_integers: [1, 3, 7]
    )
  end

  let(:other_person) do
    EqualityTest::Person.new(
      field_obj: { x: 1 },
      field_big_integer: 137,
      field_boolean: false,
      field_date: Date.new(2024, 1, 1),
      field_datetime: DateTime.new(2024, 1, 1, 1, 3, 7),
      field_float: 1.37,
      field_integer: 138,
      field_string: "string",
      field_time: Time.new(2024, 1, 1, 1, 3, 8, "UTC"),
      field_role: EqualityTest::Role.new(field_name: "other_nom"),
      field_roles: [EqualityTest::Role.new(field_name: "prenom")],
      field_integers: [1, 3, 7]
    )
  end

  context "#eql?" do
    specify do
      expect(person).to eq(same_person)
      expect(same_person).to eq(person)
      expect(same_person).to eq(same_person)

      expect(person).not_to eq(other_person)
    end
  end

  context "#==" do
    specify do
      expect(person == same_person).to be_truthy
      expect(same_person == person).to be_truthy

      expect(person == other_person).to be_falsey
    end
  end

  context "#hash" do
    specify do
      hash = { person => "test" }
      expect(hash[same_person]).to eq("test")
      expect(hash[other_person]).to be_nil
    end
  end
end
