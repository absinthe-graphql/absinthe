defmodule Absinthe.Type.InputObjectTest do
  use ExSpec, async: true

  defmodule TestSchema do
    use Absinthe.Schema

    @desc "A profile"
    input_object :profile do

      field :name, :string

      field :profile_picture,
        type: :string,
        args: [
          width: [type: :integer],
          height: [type: :integer]
        ]

    end

  end

  describe "input object" do

    it "can be defined" do
      %Absinthe.Type.InputObject{name: "Profile", description: "A profile"} = TestSchema.__absinthe_type__(:profile)
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
