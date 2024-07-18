# frozen_string_literal: true

module EntityTest
  class Role
    include ActiveModel::Entity
    attribute :name, :string
    attribute :last_name, :string
  end

  class Person
    include ActiveModel::Entity

    attribute :age, :integer
    attribute :role, :entity, class_name: "EntityTest::Role"
  end
end

RSpec.describe ActiveModel::Entity::Type::Entity do
  context "sanity" do
    let(:person) { EntityTest::Person.new }
    let(:role) { EntityTest::Role.new }

    before do
      person.age = 18
      role.name = "admin"
      role.last_name = "admin"

      person.role = role
    end

    it "supports direct model instance assignment" do
      expect(person.role).to eq(role)
    end

    it "serializes as json nicely" do
      expect(person.as_json).to eq({ age: 18, role: { name: "admin", last_name: "admin" } }.deep_stringify_keys)
    end

    it "supports nil value properly when serializing" do
      person.role = nil
      expect(person.as_json).to eq({ age: 18, role: nil }.deep_stringify_keys)
    end

    it "supports hash assigment" do
      person.role = { name: "dev", last_name: "dev" }

      expect(person.as_json).to eq({ age: 18, role: { name: "dev", last_name: "dev" } }.deep_stringify_keys)
    end
  end

  context "constructing from json" do
    it "parses itself from json" do
      person = EntityTest::Person.from_json({ age: 137, role: { name: "user", lastName: "user" } }.deep_stringify_keys)

      expect(person).to be_instance_of(EntityTest::Person)
      expect(person.age).to eq(137)
      expect(person.role).to be_instance_of(EntityTest::Role)
      expect(person.role.name).to eq("user")
      expect(person.role.last_name).to eq("user")
    end

    it "accepts nil values" do
      person = EntityTest::Person.from_json({ age: 137, role: nil }.deep_stringify_keys)

      expect(person).to be_instance_of(EntityTest::Person)
      expect(person.age).to eq(137)
      expect(person.role).to eq(nil)
    end
  end

  context "constructing from ActionController::Parameters" do
    it "parses itself from json" do
      person = EntityTest::Person.from_json(ActionController::Parameters.new({ age: 137, role: { name: "user", lastName: "user" } }))

      expect(person).to be_instance_of(EntityTest::Person)
      expect(person.age).to eq(137)
      expect(person.role).to be_instance_of(EntityTest::Role)
      expect(person.role.name).to eq("user")
      expect(person.role.last_name).to eq("user")
    end
  end
end
