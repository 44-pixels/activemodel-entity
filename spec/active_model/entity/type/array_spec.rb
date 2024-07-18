# frozen_string_literal: true

module ArrayTest
  class Role
    include ActiveModel::Entity
    attribute :name, :string
    attribute :last_name, :string
  end

  class Person
    include ActiveModel::Entity

    attribute :ages, :array, of: :integer
    attribute :roles, :array, of: "ArrayTest::Role"
  end
end

RSpec.describe ActiveModel::Entity::Type::Entity do
  context "sanity" do
    let(:person) { ArrayTest::Person.new }
    let(:role) { ArrayTest::Role.new }

    before do
      person.ages = [18, 21]
      role.name = "admin"
      role.last_name = "admin"

      person.roles = [role]
    end

    it "supports direct model instance assignment" do
      expect(person.roles).to eq([role])
    end

    it "serializes as json nicely" do
      expect(person.as_json).to eq({ ages: [18, 21], roles: [{ name: "admin", last_name: "admin" }] }.deep_stringify_keys)
    end

    it "supports [] value properly when serializing" do
      person.roles = []
      expect(person.as_json).to eq({ ages: [18, 21], roles: [] }.deep_stringify_keys)
    end

    it "supports nil value properly when serializing" do
      person.roles = nil
      expect(person.as_json).to eq({ ages: [18, 21], roles: nil }.deep_stringify_keys)
    end

    it "supports hash assigment" do
      person.roles = [{ name: "dev", last_name: "dev" }]

      expect(person.as_json).to eq({ ages: [18, 21], roles: [{ name: "dev", last_name: "dev" }] }.deep_stringify_keys)
    end
  end

  context "constructing from json" do
    it "parses itself from json" do
      person = ArrayTest::Person.from_json({ ages: [1, 3, 7], roles: [{ name: "user", lastName: "user" }] }.deep_stringify_keys)

      expect(person).to be_instance_of(ArrayTest::Person)
      expect(person.ages).to eq([1, 3, 7])
      expect(person.roles).to be_instance_of(Array)
      expect(person.roles.size).to eq(1)

      expect(person.roles.first.name).to eq("user")
    end

    it "accepts nil values" do
      person = ArrayTest::Person.from_json({ ages: [1], roles: nil }.deep_stringify_keys)

      expect(person).to be_instance_of(ArrayTest::Person)
      expect(person.ages).to eq([1])
      expect(person.roles).to eq(nil)
    end

    it "accepts [] values" do
      person = ArrayTest::Person.from_json({ ages: [1], roles: [] }.deep_stringify_keys)

      expect(person).to be_instance_of(ArrayTest::Person)
      expect(person.ages).to eq([1])
      expect(person.roles).to eq([])
    end
  end
end
