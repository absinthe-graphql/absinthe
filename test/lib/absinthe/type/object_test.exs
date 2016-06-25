defmodule Absinthe.Type.ObjectTest do
  use Absinthe.Case, async: true

  defmodule TestSchema do
    use Absinthe.Schema

    object :person do
      description "A person"

      field :name, :string

      field :profile_picture,
        type: :string,
        args: [
          width: [type: :integer],
          height: [type: :integer]
        ]

    end

  end

  describe "object" do

    it "can be defined" do
      assert %Absinthe.Type.Object{name: "Person", description: "A person"} = TestSchema.__absinthe_type__(:person)
      assert %{person: "Person"} = TestSchema.__absinthe_types__
    end

    describe "fields" do

      it "are defined" do
        obj = TestSchema.__absinthe_type__(:person)
        assert %Absinthe.Type.Field{name: "name", type: :string} = obj.fields.name
      end

    end

    describe "arguments" do

      it "are defined" do
        field = TestSchema.__absinthe_type__(:person).fields.profile_picture
        assert %Absinthe.Type.Argument{name: "width", type: :integer} = field.args.width
        assert %Absinthe.Type.Argument{name: "height", type: :integer} = field.args.height
      end

    end

  end

end
