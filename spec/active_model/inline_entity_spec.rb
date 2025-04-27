# frozen_string_literal: true

require "spec_helper"

RSpec.describe ActiveModel::InlineEntity do
  context "when defining a simple entity" do
    specify do
      described_class.define do
        name :string
      end => klass

      entity = klass.new(name: "John Doe")

      expect(entity).to be_valid
      expect(entity.name).to eq("John Doe")
    end
  end

  context "when definin a nested entity" do
    specify do
      described_class.define do
        name :string
        nested :entity do
          first_name :string
        end
      end => klass

      entity = klass.new(name: "John Doe", nested: { first_name: "John" })

      expect(entity).to be_valid
      expect(entity.name).to eq("John Doe")
      expect(entity.nested.first_name).to eq("John")
    end

    context "when defining an array of nested entities" do
      specify do
        described_class.define do
          users :array do
            name :string
            age :integer
          end
        end => klass

        entity = klass.new(users: [{ name: "John Doe", age: 30 }, { name: "Jane Doe", age: 25 }])

        expect(entity).to be_valid
        expect(entity.users.size).to eq(2)
        expect(entity.users[0]).to have_attributes(name: "John Doe", age: 30)
        expect(entity.users[1]).to have_attributes(name: "Jane Doe", age: 25)
      end
    end
  end

  context "with validations" do
    it "is invalid without a required attribute (default presence: true)" do
      klass = described_class.define do
        title :string
      end

      entity = klass.new
      expect(entity).not_to be_valid
      expect(entity.errors[:title]).to include("can't be blank")
    end

    it "allows skipping presence when overridden" do
      klass = described_class.define do
        subtitle :string, presence: false
      end

      entity = klass.new
      expect(entity).to be_valid
    end

    it "enforces custom numericality validations" do
      klass = described_class.define do
        age :integer, numericality: { greater_than_or_equal_to: 18 }
      end

      underage = klass.new(age: 17)
      expect(underage).not_to be_valid
      expect(underage.errors[:age]).to include("must be greater than or equal to 18")
    end

    it "enforces nested_entity validations" do
      klass = described_class.define do
        user :entity do
          name :string
        end
      end

      entity = klass.new(user: { name: nil })
      expect(entity).not_to be_valid
      expect(entity.errors[:user]).to include("Error in nested entity #0 for name: [\"can't be blank\"]")
    end

    it "allows to override nested_entity validations" do
      klass = described_class.define do
        user :entity, nested_entity: false do
          name :string
        end
      end

      entity = klass.new(user: { name: nil })
      expect(entity).to be_valid
    end

    it "allows custom validations on nested entities" do
      klass = described_class.define do
        user :entity, presence: { allow_nil: true } do
          name :string
        end
      end

      entity = klass.new(user: nil)
      expect(entity).to be_valid
    end
  end

  context "when passing a custom class name" do
    it "defines class under given namespace" do
      Object.const_set("CustomPrefix", Module.new)

      klass = described_class.define("CustomPrefix::Order") do
        id :integer
      end

      expect(klass.name).to eq("CustomPrefix::OrderInlineEntity")
      expect(CustomPrefix::OrderInlineEntity).to be < ActiveModel::Entity
      Object.send(:remove_const, "CustomPrefix")
    end

    it "defines class in global namespace when passing simple name" do
      klass = described_class.define("Invoice") do
        number :string
      end

      expect(klass.name).to eq("InvoiceInlineEntity")
      expect(Object.const_defined?("InvoiceInlineEntity")).to be true
    end
  end
end
