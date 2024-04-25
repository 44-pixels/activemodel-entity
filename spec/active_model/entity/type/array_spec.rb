# frozen_string_literal: true

RSpec.describe ActiveModel::Entity::Type::Entity do
  module ArrayTest
    class Role
      include ActiveModel::Entity
      attribute :name, :string
    end

    class Person
      include ActiveModel::Entity

      attribute :ages, :array, of: :integer
      attribute :roles, :array, of: 'ArrayTest::Role'
    end
  end

  context 'sanity' do
    let(:person) { ArrayTest::Person.new }
    let(:role) { ArrayTest::Role.new }

    before do
      person.ages = [18, 21]
      role.name = 'admin'

      person.roles = [role]
    end

    it 'supports direct model instance assignment' do
      expect(person.roles).to eq([role])
    end

    it 'serializes as json nicely' do
      expect(person.as_json).to eq({ ages: [18, 21], roles: [{ name: 'admin' }] }.deep_stringify_keys)
    end

    it 'supports [] value properly when serializing' do
      person.roles = []
      expect(person.as_json).to eq({ ages: [18, 21], roles: [] }.deep_stringify_keys)
    end

    it 'supports nil value properly when serializing' do
      person.roles = nil
      expect(person.as_json).to eq({ ages: [18, 21], roles: nil }.deep_stringify_keys)
    end
  end

  context 'constructing from json' do
    it 'parses itself from json' do
      person = ArrayTest::Person.from_json({ ages: [1, 3, 7], roles: [{ name: 'user' }] })

      expect(person).to be_instance_of(ArrayTest::Person)
      expect(person.ages).to eq([1, 3, 7])
      expect(person.roles).to be_instance_of(::Array)
      expect(person.roles.size).to eq(1)

      expect(person.roles.first.name).to eq('user')
    end

    it 'accepts nil values' do
      person = ArrayTest::Person.from_json({ ages: [1], roles: nil })

      expect(person).to be_instance_of(ArrayTest::Person)
      expect(person.ages).to eq([1])
      expect(person.roles).to eq(nil)
    end

    it 'accepts [] values' do
      person = ArrayTest::Person.from_json({ ages: [1], roles: [] })

      expect(person).to be_instance_of(ArrayTest::Person)
      expect(person.ages).to eq([1])
      expect(person.roles).to eq([])
    end

    it 'converts attribute name by underscoring it' do
      person = ArrayTest::Person.from_json({ Ages: [1, 3, 7], Roles: [{ Name: 'user' }] })

      expect(person).to be_instance_of(ArrayTest::Person)
      expect(person.ages).to eq([1, 3, 7])
      expect(person.roles).to be_instance_of(::Array)
      expect(person.roles.size).to eq(1)

      expect(person.roles.first.name).to eq('user')
    end
  end
end
