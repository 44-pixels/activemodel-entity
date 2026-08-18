# frozen_string_literal: true

require "active_model/entity"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Performance specs are opt-in: PERFORMANCE=1 bundle exec rspec spec/performance
  config.filter_run_excluding :performance unless ENV["PERFORMANCE"]

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
