# frozen_string_literal: true

require "spec_helper"

RSpec.describe ActiveModel::Entity::Validations::ExclusivePresenceValidator do
  subject(:dummy) { dummy_model.new(attributes) }

  fields = %i[a b c]

  let(:dummy_model) do
    Class.new do
      include ActiveModel::Model
      include ActiveModel::Validations

      attr_accessor :a, :b, :c

      validates_with ActiveModel::Entity::Validations::ExclusivePresenceValidator, fields:
    end
  end

  context "when exactly one attribute is present" do
    fields.each do |field|
      let(:attributes) { fields.index_with { nil }.tap { _1[field] = "Some Message" } }

      it "is valid when only #{field} is present" do
        expect(dummy).to be_valid
      end
    end
  end

  context "when none of the attributes are present" do
    let(:attributes) { fields.index_with { nil } }

    it "is invalid" do
      expect(dummy).not_to be_valid
      expect(dummy.errors[:base]).to include("Exactly one of #{fields.join(", ")} must be present")
    end
  end

  context "when more than one attribute is present" do
    let(:attributes) do
      {
        a: "Some message",
        b: "Another message",
        c: nil
      }
    end

    it "is invalid" do
      expect(dummy).not_to be_valid
      expect(dummy.errors[:base]).to include("Exactly one of #{fields.join(", ")} must be present")
    end
  end
end
