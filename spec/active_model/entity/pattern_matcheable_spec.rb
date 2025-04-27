# frozen_string_literal: true

require "spec_helper"

RSpec.describe ActiveModel::Entity::PatternMatcheable do
  let(:dummy) do
    Class.new do
      include ActiveModel::Entity

      attribute :int_value, :big_integer
      attribute :string_value, :string
    end.include(described_class)
  end

  specify do
    case dummy.new(int_value: 1, string_value: "test")
    in { int_value:, string_value: }
      expect(int_value).to eq(1)
      expect(string_value).to eq("test")
    end
  end

  context "when trying to match a non-existent attribute" do
    it "raises an error" do
      expect do
        case dummy.new(int_value: 1, string_value: "test")
        in { int_value: _, string_value: _, non_existent: _ }
          ""
        end
      end.to raise_error(NoMatchingPatternKeyError)
    end
  end
end
