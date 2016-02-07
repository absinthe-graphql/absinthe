defmodule Absinthe.Type.InputObjectTest do
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
            height: [type: :integer]
          ]
        ]
      ]
    ]

  end

  describe "input object" do

    it "can be defined" do
      %Absinthe.Type.InputObject{name: "Profile", description: "A profile"} = obj = TestSchema.__absinthe_type__(:profile)
      assert %{profile: "Profile"} = TestSchema.__absinthe_types__
    end

    describe "fields" do

      it "are defined" do
        obj = TestSchema.__absinthe_type__(:profile)
        assert %Absinthe.Type.Field{name: "name", type: :string} = obj.fields.name
      end

    end

    describe "arguments" do

      it "are defined" do
        field = TestSchema.__absinthe_type__(:profile).fields.profile_picture
        assert %Absinthe.Type.Argument{name: "width", type: :integer} = field.args.width
        assert %Absinthe.Type.Argument{name: "height", type: :integer} = field.args.height
      end

    end

  end

end
