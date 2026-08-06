# frozen_string_literal: true

module ReadOnlyTest
  class Address
    include ActiveModel::Entity

    attribute :city, :string
  end

  class Balance
    include ActiveModel::Entity

    attribute :id, :string, read_only: true
    attribute :amount, :float

    validates :id, presence: true
    validates :amount, presence: true
  end

  class Audit
    include ActiveModel::Entity

    attribute :who, :string, read_only: true
  end

  class Business
    include ActiveModel::Entity

    attribute :id, :string, read_only: true
    attribute :name, :string
    attribute :balance, :entity, class_name: "ReadOnlyTest::Balance"
    attribute :balances, :array, of: "ReadOnlyTest::Balance"
    attribute :address, :entity, class_name: "ReadOnlyTest::Address"
    attribute :audit, :entity, class_name: "ReadOnlyTest::Audit", read_only: true

    validates :id, presence: true
    validates :name, presence: true
  end

  class Clean
    include ActiveModel::Entity

    attribute :addr, :entity, class_name: "ReadOnlyTest::Address"
  end

  class LoopA
    include ActiveModel::Entity

    attribute :peer, :entity, class_name: "ReadOnlyTest::LoopB"
  end

  class LoopB
    include ActiveModel::Entity

    attribute :back, :entity, class_name: "ReadOnlyTest::LoopA"
  end

  class NodeA
    include ActiveModel::Entity

    attribute :secret, :string, read_only: true
    attribute :peer, :entity, class_name: "ReadOnlyTest::NodeB"
  end

  class NodeB
    include ActiveModel::Entity

    attribute :back, :entity, class_name: "ReadOnlyTest::NodeA"
  end

  # Multi-word names: the pruning in ::nested_entity_types keys off raw snake_case attribute names
  # while ::as_json_schema hides camelCase ones. Single-word fixtures cannot tell the two apart.
  class AuditLog
    include ActiveModel::Entity

    attribute :entry, :string, read_only: true
  end

  class Vendor
    include ActiveModel::Entity

    attribute :phone_numbers, :array, of: :string, read_only: true
    attribute :audit_log, :entity, class_name: "ReadOnlyTest::AuditLog", read_only: true
    attribute :display_name, :string
  end

  # A cycle where read-only-ness is reachable ONLY through the back edge, so ::read_only_subtree?
  # cannot short-circuit on its own attributes. Guards against memoizing an in-progress node as false.
  class RingHub
    include ActiveModel::Entity

    attribute :spoke, :entity, class_name: "ReadOnlyTest::RingSpoke"
    attribute :vault, :entity, class_name: "ReadOnlyTest::RingVault"
  end

  class RingSpoke
    include ActiveModel::Entity

    attribute :hub, :entity, class_name: "ReadOnlyTest::RingHub"
  end

  class RingVault
    include ActiveModel::Entity

    attribute :token, :string, read_only: true
  end

  class Shapes
    include ActiveModel::Entity

    attribute :a, :string, read_only: true
    attribute :b, :integer, default: 7, read_only: true
    attribute :c, :boolean, read_only: true
    attribute :d, :entity, class_name: "ReadOnlyTest::Address", read_only: true
    attribute :e, :array, of: "ReadOnlyTest::Address", read_only: true
    attribute :f, read_only: true
    attribute :g, :string
  end

  class Described
    include ActiveModel::Entity

    desc "the described entity"
    desc "the identifier"
    attribute :id, :string, read_only: true
    desc "the label"
    attribute :label, :string
  end

  class Parent
    include ActiveModel::Entity

    attribute :pid, :string, read_only: true
  end

  class Sub < Parent
    attribute :extra, :string, read_only: true
  end

  class Sub2 < Parent
  end
end

RSpec.describe ActiveModel::Entity::Schemas::ReadOnly do
  it "works" do
    schema = ReadOnlyTest::Balance.as_json_schema

    expect(schema).to eq({
      type: :object,
      required: %w[id amount],
      properties: {
        "id" => { type: :string, readOnly: true },
        "amount" => { type: :number }
      }
    })
  end

  describe "the read_only: option on ::attribute" do
    it "is accepted on every declaration shape" do
      expect(ReadOnlyTest::Shapes.read_only_attributes).to eq(%w[a b c d e f])
    end

    it "does not swallow other attribute options" do
      expect(ReadOnlyTest::Shapes.new.b).to eq(7)
    end
  end

  describe "the request variant of a flat entity" do
    it "refs the stripped component" do
      expect(ReadOnlyTest::Balance.json_schema_ref(:request)).to eq("#/components/schemas/ReadOnlyTest.Balance-Request")
    end

    it "drops read-only attributes from both properties and required" do
      expect(ReadOnlyTest::Balance.as_json_schema(variant: :request)).to eq({
        type: :object,
        required: %w[amount],
        properties: { "amount" => { type: :number } }
      })
    end
  end

  describe "the request variant of a nested entity" do
    it "strips transitively and refs variants from variants" do
      expect(ReadOnlyTest::Business.json_schema_variants).to eq({
        "ReadOnlyTest.Business-Request" => {
          type: :object,
          required: %w[name],
          properties: {
            "name" => { type: :string },
            "balance" => { :$ref => "#/components/schemas/ReadOnlyTest.Balance-Request" },
            "balances" => { items: { :$ref => "#/components/schemas/ReadOnlyTest.Balance-Request" }, type: :array },
            "address" => { :$ref => "#/components/schemas/ReadOnlyTest.Address" }
          }
        },
        "ReadOnlyTest.Balance-Request" => {
          type: :object,
          required: %w[amount],
          properties: { "amount" => { type: :number } }
        }
      })
    end

    it "only emits variants that something refs" do
      expect(ReadOnlyTest::Audit.read_only_subtree?).to be(true)
      expect(ReadOnlyTest::Business.json_schema_variants.keys).to eq(
        ["ReadOnlyTest.Business-Request", "ReadOnlyTest.Balance-Request"]
      )
    end

    it "composes with inline: true" do
      schema = ReadOnlyTest::Business.as_json_schema(inline: true, variant: :request)

      expect(schema[:properties]["balance"]).to eq({
        type: :object,
        required: %w[amount],
        properties: { "amount" => { type: :number } }
      })
    end
  end

  describe "a nested entity whose children have no read-only attributes" do
    it "emits no variant" do
      expect(ReadOnlyTest::Clean.json_schema_variants).to eq({})
    end

    it "resolves the request ref to the plain component" do
      expect(ReadOnlyTest::Clean.json_schema_ref(:request)).to eq("#/components/schemas/ReadOnlyTest.Clean")
      expect(ReadOnlyTest::Address.json_schema_ref(:request)).to eq("#/components/schemas/ReadOnlyTest.Address")
    end
  end

  describe "a cyclic entity graph" do
    it "terminates and elides when nothing is read-only" do
      expect(ReadOnlyTest::LoopA.read_only_subtree?).to be(false)
      expect(ReadOnlyTest::LoopA.json_schema_variants).to eq({})
      expect(ReadOnlyTest::LoopA.json_schema_ref(:request)).to eq("#/components/schemas/ReadOnlyTest.LoopA")
    end

    it "sees read-only-ness reached only through the cycle" do
      expect(ReadOnlyTest::NodeB.read_only_subtree?).to be(true)
    end

    it "emits each component once from either entry point" do
      expect(ReadOnlyTest::NodeA.json_schema_variants.keys).to eq(
        ["ReadOnlyTest.NodeA-Request", "ReadOnlyTest.NodeB-Request"]
      )
      expect(ReadOnlyTest::NodeB.json_schema_variants.keys).to eq(
        ["ReadOnlyTest.NodeB-Request", "ReadOnlyTest.NodeA-Request"]
      )
    end
  end

  describe "readOnly on the full schema" do
    it "wraps a $ref property in allOf" do
      expect(ReadOnlyTest::Business.as_json_schema[:properties]["audit"]).to eq({
        allOf: [{ :$ref => "#/components/schemas/ReadOnlyTest.Audit" }],
        readOnly: true
      })
    end
  end

  describe "BE-47 leaking read-only information to subclasses" do
    it "keeps every class's list to itself" do
      expect(ReadOnlyTest::Parent.read_only_attributes).to eq(%w[pid])
      expect(ReadOnlyTest::Sub.read_only_attributes).to eq(%w[pid extra])
      expect(ReadOnlyTest::Sub2.read_only_attributes).to eq(%w[pid])
    end
  end

  describe "the ::attribute super chain" do
    it "keeps desc annotations aligned with their attributes" do
      expect(ReadOnlyTest::Described.meta_descriptions).to eq({
        nil => ["the described entity"],
        id: "the identifier",
        label: "the label"
      })
    end

    it "still emits descriptions alongside readOnly" do
      expect(ReadOnlyTest::Described.as_json_schema[:properties]["id"]).to eq({
        type: :string,
        description: "the identifier",
        readOnly: true
      })
    end
  end

  describe "an unknown variant" do
    it "raises rather than silently returning the base ref" do
      expect { ReadOnlyTest::Business.json_schema_ref(:requst) }.to raise_error(KeyError)
    end

    it "raises on a flat entity too, which has no nested $ref to route the check through" do
      expect { ReadOnlyTest::Balance.as_json_schema(variant: :requst) }.to raise_error(KeyError)
    end
  end

  describe "multi-word attribute names" do
    it "strips them from the variant despite the snake_case/camelCase split" do
      expect(ReadOnlyTest::Vendor.as_json_schema(variant: :request)[:properties].keys).to eq(["displayName"])
    end

    it "emits no variant for an entity reachable only through a read-only edge" do
      expect(ReadOnlyTest::Vendor.json_schema_variants.keys).to eq(["ReadOnlyTest.Vendor-Request"])
    end
  end

  describe "a cycle whose read-only-ness is only reachable through the back edge" do
    it "reports the subtree dirty from every entry point" do
      expect(ReadOnlyTest::RingHub.read_only_subtree?).to be(true)
      expect(ReadOnlyTest::RingSpoke.read_only_subtree?).to be(true)
    end

    it "emits a variant for the node that has no read-only attribute of its own" do
      expect(ReadOnlyTest::RingHub.json_schema_variants.keys).to contain_exactly(
        "ReadOnlyTest.RingHub-Request",
        "ReadOnlyTest.RingSpoke-Request",
        "ReadOnlyTest.RingVault-Request"
      )
    end
  end

  describe "runtime behaviour" do
    it "is unaffected: read-only is schema-only metadata" do
      expect(ReadOnlyTest::Business.from_json({ "id" => "x" }).id).to eq("x")
    end
  end
end
