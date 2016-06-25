defmodule Absinthe.Type.DeprecationTest do
  use Absinthe.Case, async: true

  alias Absinthe.Type

  defmodule TestSchema do
    use Absinthe.Schema

    input_object :profile do
      description "A profile"

      field :name, :string

      field :profile_picture,
        type: :string,
        args: [
          width: [type: :integer],
          height: [type: :integer],
          size: [type: :string, deprecate: "Not explicit enough"],
          source: [type: :string, deprecate: true]
        ]

      field :email_address, :string do
        deprecate "privacy"
      end

      field :address, :string, deprecate: true

    end

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
