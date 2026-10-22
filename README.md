# Activemodel::Entity

TODO: Delete this and the text below, and describe your gem

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/activemodel/entity`. To experiment with that code, run `bin/console` for an interactive prompt.

## Installation

TODO: Replace `UPDATE_WITH_YOUR_GEM_NAME_IMMEDIATELY_AFTER_RELEASE_TO_RUBYGEMS_ORG` with your gem name right after releasing it to RubyGems.org. Please do not do it earlier due to security reasons. Alternatively, replace this section with instructions to install your gem from git if you don't plan to release to RubyGems.org.

Install the gem and add to the application's Gemfile by executing:

    $ bundle add UPDATE_WITH_YOUR_GEM_NAME_IMMEDIATELY_AFTER_RELEASE_TO_RUBYGEMS_ORG

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install UPDATE_WITH_YOUR_GEM_NAME_IMMEDIATELY_AFTER_RELEASE_TO_RUBYGEMS_ORG

## Usage

### Discriminated unions

A base entity can name a tag attribute and a closed mapping of tag to subclass, STI-style.
Mapping values may be class names of classes defined later, or constants:

```ruby
class ThreadContext
  include ActiveModel::Entity

  discriminated_by :type, admin: "ThreadContext::Admin", whatsapp: "ThreadContext::Whatsapp"
end

class ThreadContext::Admin < ThreadContext; end

class ThreadContext::Whatsapp < ThreadContext
  attribute :phone_number_id, :string
  attribute :wa_id, :string
end
```

`discriminated_by` declares the `type` string attribute on the base unless it already exists. Each
subclass gets its tag as the attribute's default, `represent` serializes it, and a subclass whose tag
does not match its mapping entry is invalid.

Building through the base dispatches on the tag (string or symbol key; `from_json` reads the
camelized key like any other attribute); a missing or unknown tag raises an `ArgumentError`. Building
a subclass directly works as before:

```ruby
ThreadContext.new(type: "whatsapp", wa_id: "1")          # => #<ThreadContext::Whatsapp ...>
ThreadContext.from_json("type" => "admin")                # => #<ThreadContext::Admin ...>
ThreadContext::Whatsapp.new(wa_id: "1").type              # => "whatsapp"
ThreadContext.new(type: "sms")                            # ArgumentError: unknown type tag "sms"
```

Attributes typed with the base (`attribute :context, :entity, class_name: "ThreadContext"`,
`attribute :contexts, :array, of: "ThreadContext"`) cast hashes to the matching subclass and keep
subclass instances as they are.

The base's JSON schema is a `oneOf` of the subclasses with an OpenAPI 3 `discriminator`; each
subclass pins its tag as a required single-value enum:

```ruby
ThreadContext.as_json_schema
# {
#   oneOf: [{ "$ref": "#/components/schemas/ThreadContext.Admin" }, { "$ref": "#/components/schemas/ThreadContext.Whatsapp" }],
#   discriminator: {
#     propertyName: "type",
#     mapping: { "admin" => "#/components/schemas/ThreadContext.Admin", "whatsapp" => "#/components/schemas/ThreadContext.Whatsapp" }
#   }
# }

ThreadContext::Whatsapp.as_json_schema
# {
#   type: :object,
#   required: ["type"],
#   properties: {
#     "type" => { type: :string, enum: ["whatsapp"] },
#     "phoneNumberId" => { type: :string },
#     "waId" => { type: :string }
#   }
# }
```

With `inline: true` the `oneOf` carries the subclass schemas themselves and the `discriminator` keeps
only `propertyName`, since there are no refs for a `mapping` to point at.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/activemodel-entity.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
