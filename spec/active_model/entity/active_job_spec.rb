# frozen_string_literal: true

require "spec_helper"

require "active_job"
require "active_model/entity/active_job"
require "active_job/arguments"

ActiveJob::Serializers.add_serializers(ActiveJob::Serializers::ActiveModelSerializer)

RSpec.describe ActiveJob::Serializers::ActiveModelSerializer do
  subject(:entity) { klass.new(text: "hello", number: 1) }

  let(:klass) do
    Class.new do
      include ActiveModel::Entity

      attribute :text, :string
      attribute :number, :integer
    end
  end

  before do
    stub_const("MyClass", klass)
  end

  it "serializes things back and forth" do
    expect(ActiveJob::Arguments.deserialize(ActiveJob::Arguments.serialize([entity]))).to eq([entity])
  end
end
