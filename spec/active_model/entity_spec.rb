# frozen_string_literal: true

RSpec.describe ActiveModel::Entity do
  it "has a version number" do
    expect(ActiveModel::Entity::VERSION).not_to be nil
  end
end
