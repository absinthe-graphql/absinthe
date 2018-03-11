defmodule Absinthe.Type.ObjectTest do
  use Absinthe.Case, async: true

  defmodule Schema do
    use Absinthe.Schema

    query do
      # Must exist
    end

    @desc "A person"
    object :person do
      description "A person"

      field :name, :string

      field :profile_picture, :string do
        arg :width, :integer
        arg :height, :integer
      end
    end
  end

  describe "object types" do
    test "can be defined" do
      assert %Absinthe.Type.Object{name: "Person", description: "A person"} =
               Schema.__absinthe_type__(:person)

      assert %{person: "Person"} = Schema.__absinthe_types__()
    end

    test "can define fields" do
      obj = Schema.__absinthe_type__(:person)
      assert %Absinthe.Type.Field{name: "name", type: :string} = obj.fields.name
    end

    test "can define field arguments" do
      field = Schema.__absinthe_type__(:person).fields.profile_picture
      assert %Absinthe.Type.Argument{name: "width", type: :integer} = field.args.width
      assert %Absinthe.Type.Argument{name: "height", type: :integer} = field.args.height
    end
  end
end
