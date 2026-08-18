# frozen_string_literal: true

# Entities used by the representation performance spec.
#
# Excluded from the default suite — run with:
#   PERFORMANCE=1 bundle exec rspec spec/performance
#
# The graph mirrors a realistically "wide" payload:
#   Catalog (root entity)
#     └── products: array of 5000 Product entities, each with
#           ├── regular fields (integer, string, float, boolean, datetime, array of strings)
#           └── dimensions: a nested Dimensions entity with a few fields
module RepresentPerformanceTest
  # How many nested entities the root entity carries.
  NESTED_ENTITIES_COUNT = 5_000

  # Generous per-call budget for representing the whole catalog. A healthy run is
  # ~200ms on a laptop; the budget only guards against catastrophic regressions
  # (e.g. accidentally quadratic serialization) without flaking on slow hardware.
  TIME_BUDGET_SECONDS = 2.0

  class Dimensions
    include ActiveModel::Entity

    attribute :width, :float
    attribute :height, :float
    attribute :unit, :string
  end

  class Product
    include ActiveModel::Entity

    attribute :id, :integer
    attribute :name, :string
    attribute :price, :float
    attribute :in_stock, :boolean
    attribute :created_at, :datetime
    attribute :tags, :array, of: :string
    attribute :dimensions, :entity, class_name: "RepresentPerformanceTest::Dimensions"
  end

  class Catalog
    include ActiveModel::Entity

    attribute :id, :integer
    attribute :name, :string
    attribute :products, :array, of: "RepresentPerformanceTest::Product"
  end
end

RSpec.describe "ActiveModel::Entity representation performance", :performance do
  let(:items_count) { RepresentPerformanceTest::NESTED_ENTITIES_COUNT }
  let(:created_at) { Time.utc(2024, 6, 1, 12, 30) }

  def represent_catalog(source)
    RepresentPerformanceTest::Catalog.represent(source)
  end

  def measure_represent(source, iterations: 5, warmup: 2)
    warmup.times { represent_catalog(source) }

    Array.new(iterations) do
      started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      represent_catalog(source)
      Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at
    end
  end

  def report_timings(label, timings)
    milliseconds = timings.map { _1 * 1000 }
    average = milliseconds.sum / milliseconds.size
    stats = "min #{milliseconds.min.round(1)}ms / avg #{average.round(1)}ms / max #{milliseconds.max.round(1)}ms over #{milliseconds.size} runs"

    RSpec.configuration.reporter.message("Catalog.represent (#{label}, #{items_count} products): #{stats}")
  end

  shared_examples "a large catalog representation" do |label|
    it "represents every nested entity" do
      json = represent_catalog(source)

      expect(json["products"].length).to eq(items_count)
      expect(json["products"].first).to eq(
        "id" => 0,
        "name" => "Product 0",
        "price" => 0.0,
        "inStock" => true,
        "createdAt" => created_at,
        "tags" => %w[tag-0 featured],
        "dimensions" => { "width" => 10.0, "height" => 20.0, "unit" => "cm" }
      )
    end

    it "stays within the time budget" do
      timings = measure_represent(source)

      report_timings(label, timings)

      # The fastest run is the least noisy statistic on shared CI hardware.
      expect(timings.min).to be < RepresentPerformanceTest::TIME_BUDGET_SECONDS
    end
  end

  context "when representing a hash payload" do
    let(:source) do
      {
        id: 1,
        name: "Catalog",
        products: Array.new(items_count) do |index|
          {
            id: index,
            name: "Product #{index}",
            price: index * 1.5,
            in_stock: index.even?,
            created_at:,
            tags: ["tag-#{index % 10}", "featured"],
            dimensions: { width: 10.0 + index, height: 20.0 + index, unit: "cm" }
          }
        end
      }
    end

    include_examples "a large catalog representation", "hash payload"
  end

  context "when representing an entity object graph" do
    let(:source) do
      RepresentPerformanceTest::Catalog.new(
        id: 1,
        name: "Catalog",
        products: Array.new(items_count) do |index|
          RepresentPerformanceTest::Product.new(
            id: index,
            name: "Product #{index}",
            price: index * 1.5,
            in_stock: index.even?,
            created_at:,
            tags: ["tag-#{index % 10}", "featured"],
            dimensions: RepresentPerformanceTest::Dimensions.new(width: 10.0 + index, height: 20.0 + index, unit: "cm")
          )
        end
      )
    end

    include_examples "a large catalog representation", "entity object graph"
  end
end
