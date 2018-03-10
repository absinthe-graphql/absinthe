defmodule Absinthe.Type.InputObjectTest do
  use Absinthe.Case, async: true

  defmodule Schema do
    use Absinthe.Schema

    query do
      # Query type must exist
    end

    @desc "A profile"
    input_object :profile do
      field :name, :string
      field :profile_picture, :string
    end
  end

  describe "input object types" do
    test "can be defined" do
      assert %Absinthe.Type.InputObject{name: "Profile", description: "A profile"} =
               Schema.__absinthe_type__(:profile)

      assert %{profile: "Profile"} = Schema.__absinthe_types__()
    end

    test "can define fields" do
      obj = Schema.__absinthe_type__(:profile)
      assert %Absinthe.Type.Field{name: "name", type: :string} = obj.fields.name
    end
  end
end
