# frozen_string_literal: true

module DiscriminatorTest
  class ThreadContext
    include ActiveModel::Entity

    desc "Where a thread came from"
    desc "Which kind of context this is"
    attribute :type, :string

    discriminated_by :type, admin: "DiscriminatorTest::Admin", whatsapp: "DiscriminatorTest::Whatsapp"
  end

  class Admin < ThreadContext; end

  class Whatsapp < ThreadContext
    attribute :phone_number_id, :string
    attribute :wa_id, :string

    validates :wa_id, presence: true
  end

  class Thread
    include ActiveModel::Entity

    attribute :context, :entity, class_name: "DiscriminatorTest::ThreadContext"
    attribute :contexts, :array, of: "DiscriminatorTest::ThreadContext"

    validates_nested
  end

  # Constants in the mapping, subclasses declared before the mapping, a multi-word tag attribute.
  class Shape
    include ActiveModel::Entity

    class Circle < self; end
    class Square < self; end

    discriminated_by :shape_kind, circle: Circle, square: Square
  end
end

RSpec.describe ActiveModel::Entity::Discriminator do
  let(:admin_ref) { "#/components/schemas/DiscriminatorTest.Admin" }
  let(:whatsapp_ref) { "#/components/schemas/DiscriminatorTest.Whatsapp" }

  describe "the tag attribute" do
    it "is set on new and serialized by represent" do
      expect(DiscriminatorTest::Admin.new.type).to eq("admin")
      expect(DiscriminatorTest::Whatsapp.new(wa_id: "1").type).to eq("whatsapp")
      expect(DiscriminatorTest::Admin.represent(DiscriminatorTest::Admin.new)).to eq({ "type" => "admin" })
      expect(DiscriminatorTest::Whatsapp.represent(DiscriminatorTest::Whatsapp.new(wa_id: "1")))
        .to eq({ "type" => "whatsapp", "phoneNumberId" => nil, "waId" => "1" })
    end

    it "is set on subclasses declared before the mapping" do
      expect(DiscriminatorTest::Shape::Circle.new.shape_kind).to eq("circle")
      expect(DiscriminatorTest::Shape::Square.new.shape_kind).to eq("square")
    end
  end

  describe "dispatch on the base" do
    it "builds the subclass from json with string keys" do
      context = DiscriminatorTest::ThreadContext.from_json({ "type" => "whatsapp", "waId" => "1" })

      expect(context).to be_instance_of(DiscriminatorTest::Whatsapp)
      expect(context.wa_id).to eq("1")
    end

    it "builds the subclass from json with symbol keys" do
      expect(DiscriminatorTest::ThreadContext.from_json({ type: :admin })).to be_instance_of(DiscriminatorTest::Admin)
    end

    it "builds the subclass from ActionController::Parameters" do
      context = DiscriminatorTest::ThreadContext.from_json(ActionController::Parameters.new(type: "whatsapp", waId: "1"))

      expect(context).to be_instance_of(DiscriminatorTest::Whatsapp)
      expect(context.wa_id).to eq("1")
    end

    it "builds the subclass with new" do
      expect(DiscriminatorTest::ThreadContext.new(type: "whatsapp", wa_id: "1")).to be_instance_of(DiscriminatorTest::Whatsapp)
      expect(DiscriminatorTest::ThreadContext.new({ "type" => "admin" })).to be_instance_of(DiscriminatorTest::Admin)
    end

    it "honours the camelized tag key in from_json and the plain one in new" do
      expect(DiscriminatorTest::Shape.from_json({ "shapeKind" => "circle" })).to be_instance_of(DiscriminatorTest::Shape::Circle)
      expect(DiscriminatorTest::Shape.new(shape_kind: "square")).to be_instance_of(DiscriminatorTest::Shape::Square)
    end

    it "builds a subclass directly regardless of the tag" do
      expect(DiscriminatorTest::Whatsapp.new(wa_id: "1")).to be_instance_of(DiscriminatorTest::Whatsapp)
      expect(DiscriminatorTest::Admin.from_json({ "type" => "admin" })).to be_instance_of(DiscriminatorTest::Admin)
      expect(DiscriminatorTest::Admin.new(type: "whatsapp")).to be_instance_of(DiscriminatorTest::Admin)
    end

    it "raises on an unknown tag" do
      expect { DiscriminatorTest::ThreadContext.new(type: "sms") }
        .to raise_error(ArgumentError, 'DiscriminatorTest::ThreadContext: unknown type tag "sms", expected one of "admin", "whatsapp"')
    end

    it "raises on a missing tag" do
      expect { DiscriminatorTest::ThreadContext.from_json({ "waId" => "1" }) }
        .to raise_error(ArgumentError, 'DiscriminatorTest::ThreadContext: missing type tag, expected one of "admin", "whatsapp"')
    end

    it "represents through the base using the subclass" do
      whatsapp = DiscriminatorTest::Whatsapp.new(wa_id: "1")

      expect(DiscriminatorTest::ThreadContext.represent(whatsapp)).to eq({ "type" => "whatsapp", "phoneNumberId" => nil, "waId" => "1" })
      expect(DiscriminatorTest::ThreadContext.represent({ type: "admin" })).to eq({ "type" => "admin" })
    end
  end

  describe "as a nested attribute" do
    it "casts a hash to the right subclass" do
      thread = DiscriminatorTest::Thread.new(context: { type: "whatsapp", wa_id: "1" })

      expect(thread.context).to be_instance_of(DiscriminatorTest::Whatsapp)
      expect(thread.context.wa_id).to eq("1")
    end

    it "parses json to the right subclass" do
      thread = DiscriminatorTest::Thread.from_json({ "context" => { "type" => "admin" } })

      expect(thread.context).to be_instance_of(DiscriminatorTest::Admin)
    end

    it "keeps a subclass instance" do
      admin = DiscriminatorTest::Admin.new

      expect(DiscriminatorTest::Thread.new(context: admin).context).to equal(admin)
      expect(DiscriminatorTest::Thread.new(contexts: [admin]).contexts.first).to equal(admin)
    end

    it "casts an array of hashes to the right subclasses" do
      thread = DiscriminatorTest::Thread.from_json({ "contexts" => [{ "type" => "admin" }, { "type" => "whatsapp", "waId" => "1" }] })

      expect(thread.contexts.map(&:class)).to eq([DiscriminatorTest::Admin, DiscriminatorTest::Whatsapp])
      expect(thread.contexts.last.wa_id).to eq("1")
    end

    it "represents with the subclass attributes" do
      thread = DiscriminatorTest::Thread.new(context: { type: "whatsapp", wa_id: "1" }, contexts: [{ type: "admin" }, nil])

      expect(DiscriminatorTest::Thread.represent(thread)).to eq({
        "context" => { "type" => "whatsapp", "phoneNumberId" => nil, "waId" => "1" },
        "contexts" => [{ "type" => "admin" }, nil]
      })
    end
  end

  describe "validation" do
    it "rejects a tag that is not the subclass's own" do
      context = DiscriminatorTest::Admin.new(type: "whatsapp")

      expect(context).not_to be_valid
      expect(context.errors[:type]).to eq(["is not included in the list"])
      expect(DiscriminatorTest::Admin.new(type: nil)).not_to be_valid
    end

    it "validates the nested subclass's own attributes" do
      expect(DiscriminatorTest::Thread.new(context: { type: "whatsapp", wa_id: "1" })).to be_valid

      thread = DiscriminatorTest::Thread.new(context: { type: "whatsapp" }, contexts: [{ type: "admin" }])

      expect(thread).not_to be_valid
      expect(thread.errors[:context]).to eq(['Error in nested entity #0 for wa_id: ["can\'t be blank"]'])
      expect(thread.errors[:contexts]).to be_empty
    end
  end

  describe "equality" do
    it "holds between two same-tag instances" do
      expect(DiscriminatorTest::Admin.new).to eq(DiscriminatorTest::Admin.new)
      expect(DiscriminatorTest::ThreadContext.new(type: "admin")).to eq(DiscriminatorTest::Admin.new)
      expect(DiscriminatorTest::Whatsapp.new(wa_id: "1")).not_to eq(DiscriminatorTest::Whatsapp.new(wa_id: "2"))
      expect(DiscriminatorTest::Admin.new.inspect).to eq("#<DiscriminatorTest::Admin #{{ "type" => "admin" }.inspect}>")
    end
  end

  describe "json schema" do
    it "emits oneOf of refs with a discriminator mapping for the base" do
      expect(DiscriminatorTest::ThreadContext.as_json_schema).to eq({
        oneOf: [{ "$ref": admin_ref }, { "$ref": whatsapp_ref }],
        discriminator: { propertyName: "type", mapping: { "admin" => admin_ref, "whatsapp" => whatsapp_ref } },
        description: "Where a thread came from"
      })
    end

    it "emits oneOf of inline schemas for the base" do
      expect(DiscriminatorTest::ThreadContext.as_json_schema(inline: true)).to eq({
        oneOf: [DiscriminatorTest::Admin.as_json_schema(inline: true), DiscriminatorTest::Whatsapp.as_json_schema(inline: true)],
        discriminator: { propertyName: "type" },
        description: "Where a thread came from"
      })
    end

    it "fixes the tag as a required enum on a subclass" do
      expect(DiscriminatorTest::Admin.as_json_schema).to eq({
        type: :object,
        required: ["type"],
        properties: { "type" => { type: :string, enum: ["admin"], description: "Which kind of context this is" } }
      })

      expect(DiscriminatorTest::Whatsapp.as_json_schema).to eq({
        type: :object,
        required: %w[waId type],
        properties: {
          "type" => { type: :string, enum: ["whatsapp"], description: "Which kind of context this is" },
          "phoneNumberId" => { type: :string },
          "waId" => { type: :string }
        }
      })
    end

    it "camelizes the discriminator property name" do
      expect(DiscriminatorTest::Shape.as_json_schema[:discriminator][:propertyName]).to eq("shapeKind")
      expect(DiscriminatorTest::Shape::Circle.as_json_schema[:properties]["shapeKind"]).to eq({ type: :string, enum: ["circle"] })
    end

    it "refers to the base from an attribute typed with it" do
      schema = DiscriminatorTest::Thread.as_json_schema

      expect(schema[:properties]["context"]).to eq({ "$ref": "#/components/schemas/DiscriminatorTest.ThreadContext" })
      expect(schema[:properties]["contexts"]).to eq({ items: { "$ref": "#/components/schemas/DiscriminatorTest.ThreadContext" }, type: :array })
    end

    it "inlines the union into an attribute typed with it" do
      schema = DiscriminatorTest::Thread.as_json_schema(inline: true)

      expect(schema[:properties]["context"]).to eq(DiscriminatorTest::ThreadContext.as_json_schema(inline: true))
      expect(schema[:properties]["contexts"][:items]).to eq(DiscriminatorTest::ThreadContext.as_json_schema(inline: true))
    end
  end
end
