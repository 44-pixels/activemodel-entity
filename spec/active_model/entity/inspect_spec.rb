# frozen_string_literal: true

module InspectTest
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
    attribute :field_role, :entity, class_name: "InspectTest::Role"
    attribute :field_roles, :array, of: "InspectTest::Role"
    attribute :field_integers, :array, of: :integer
  end
end

RSpec.describe ActiveModel::Entity::Inspect do
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
      field_time: Time.new(2024, 1, 1, 1, 3, 8, "UTC"),
      field_role: { field_name: "nom" },
      field_roles: [{ field_name: "prenom" }],
      field_integers: [1, 3, 7]
    }
  end

  it "works" do
    person = InspectTest::Person.new(source)
    result = <<~RESULT.strip
      #<InspectTest::Person {"field_obj"=>{"x"=>1}, "field_big_integer"=>137, "field_boolean"=>false, "field_date"=>"2024-01-01", "field_datetime"=>"2024-01-01T01:03:07.000+00:00", "field_float"=>1.37, "field_integer"=>138, "field_string"=>"string", "field_time"=>"2024-01-01T01:03:08.000Z", "field_role"=>{"field_name"=>"nom"}, "field_roles"=>[{"field_name"=>"prenom"}], "field_integers"=>[1, 3, 7]}>
    RESULT

    expect(person.inspect).to eq(result)
  end
end
