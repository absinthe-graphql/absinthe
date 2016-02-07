defmodule Absinthe.Type.DeprecationTest do
  use ExSpec, async: true

  alias Absinthe.Type

  defmodule TestSchema do
    use Absinthe.Schema

    @doc "A profile"
    input_object :profile, [
      fields: [
        name: [type: :string],
        profile_picture: [
          type: :string,
          args: [
            width: [type: :integer],
            height: [type: :integer],
            size: deprecate([type: :string], reason: "Not explicit enough"),
            source: deprecate([type: :string])
          ]
        ],
        email_address: deprecate([type: :string], reason: "privacy"),
        address: deprecate([type: :string])
      ]
    ]

  end

  describe "fields" do

    it "can be deprecated" do
      obj = TestSchema.__absinthe_type__(:profile)
      assert Type.deprecated?(obj.fields.email_address)
      assert "privacy" == obj.fields.email_address.deprecation.reason
      assert Type.deprecated?(obj.fields.address)
      assert nil == obj.fields.address.deprecation.reason
    end

  end

  describe "arguments" do

    it "can be deprecated" do
      field = TestSchema.__absinthe_type__(:profile).fields.profile_picture
      assert Type.deprecated?(field.args.size)
      assert "Not explicit enough" == field.args.size.deprecation.reason
      assert Type.deprecated?(field.args.source)
      assert nil == field.args.source.deprecation.reason
    end

  end

end
