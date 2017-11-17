defmodule Absinthe.Type.ImportTypesTest do
  use Absinthe.Case, async: true

  defmodule TestSchema do
    use Absinthe.Schema

    import_types Absinthe.Type.Custom.{TypeA, TypeB}

    query do
      field :apple, :type_a
      field :bob, :type_b
    end

  end

  context "imported types" do

    # it "can be defined" do
    #   assert %Absinthe.Type.InputObject{name: "Profile", description: "A profile"} = TestSchema.__absinthe_type__(:type_a)
    #   assert %{profile: "Profile"} = TestSchema.__absinthe_types__
    # end

    context "types" do

      it "are defined" do
        type_a = TestSchema.__absinthe_type__(:type_a)
        type_b = TestSchema.__absinthe_type__(:type_b)
        assert type_a == type_b
      end

    end

    # context "arguments" do

    #   it "are defined" do
    #     field = TestSchema.__absinthe_type__(:profile).fields.profile_picture
    #     assert %Absinthe.Type.Argument{name: "width", type: :integer} = field.args.width
    #     assert %Absinthe.Type.Argument{name: "height", type: :integer} = field.args.height
    #   end

    # end

  end

end
