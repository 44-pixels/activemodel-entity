# frozen_string_literal: true

require "spec_helper"

RSpec.describe ActiveModel::Entity::Validations::NestedEntityValidator do
  let(:dummy_child) do
    Class.new do
      include ActiveModel::Entity

      attribute :name, :string

      validates :name, presence: true
    end
  end
  let(:dummy_parent) do
    Class.new do
      include ActiveModel::Entity

      attribute :child, :entity, class_name: "ChildEntity"
      attribute :children, :array, of: "ChildEntity"

      validates :child, :children, nested_entity: true
    end
  end
  let(:entity) { dummy_parent.new(child: {}, children: [{}]) }

  before { stub_const("ChildEntity", dummy_child) }

  specify do
    expect(entity).not_to be_valid
    expect(entity.errors[:child]).to include('Error in nested entity #0 for name: ["can\'t be blank"]')
    expect(entity.errors[:children]).to include('Error in nested entity #0 for name: ["can\'t be blank"]')
  end

  context "when validations are defined via validates_nested" do
    let(:dummy_parent) do
      Class.new do
        include ActiveModel::Entity

        attribute :child, :entity, class_name: "ChildEntity"
        attribute :children, :array, of: "ChildEntity"

        validates_nested
      end
    end

    specify do
      expect(entity).not_to be_valid
      expect(entity.errors[:child]).to include('Error in nested entity #0 for name: ["can\'t be blank"]')
      expect(entity.errors[:children]).to include('Error in nested entity #0 for name: ["can\'t be blank"]')
    end
  end
end
