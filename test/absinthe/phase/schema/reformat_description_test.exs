defmodule Absinthe.Phase.Schema.ReformatDescriptionTest do
  use Absinthe.Case, async: true

  defmodule Schema do
    use Absinthe.Schema

    query do
      # Must exist
    end

    object :via_macro do
      description "  Description via macro  "

      field :foo, :string do
        description "  Description via macro  "
      end
    end

    object :via_attribute, description: "  Description via attribute  " do
      field :foo, :string, description: "  Description via attribute  "
    end

    @desc "  Description via module attribute  "
    object :via_module_attribute do
      @desc "  Description via module attribute  "
      field :foo, :string
    end

    def desc(), do: "  Description via function  "

    object :via_function, description: desc() do
      field :foo, :string, description: desc()
    end

    import_sdl """
    "  Description via SDL  "
    type ViaSdl {
      "  Description via SDL  "
      foo: String
    }

    "  Description on Enum  "
    enum OnEnum {
      "  Description on Enum  "
      FOO
    }

    "  Description on Scalar  "
    scalar OnScalar
    """
  end

  describe "Description trimming" do
    test "via macro" do
      type = Schema.__absinthe_type__(:via_macro)

      assert %{description: "Description via macro"} = type
      assert %{description: "Description via macro"} = type.fields.foo
    end

    test "via attribute" do
      type = Schema.__absinthe_type__(:via_attribute)

      assert %{description: "Description via attribute"} = type
      assert %{description: "Description via attribute"} = type.fields.foo
    end

    test "via module attribute" do
      type = Schema.__absinthe_type__(:via_module_attribute)

      assert %{description: "Description via module attribute"} = type
      assert %{description: "Description via module attribute"} = type.fields.foo
    end

    test "via function" do
      type = Schema.__absinthe_type__(:via_function)

      assert %{description: "Description via function"} = type
      assert %{description: "Description via function"} = type.fields.foo
    end

    test "via SDL" do
      type = Schema.__absinthe_type__(:via_sdl)

      assert %{description: "Description via SDL"} = type
      assert %{description: "Description via SDL"} = type.fields.foo
    end

    test "on Enum" do
      type = Schema.__absinthe_type__(:on_enum)

      assert %{description: "Description on Enum"} = type
      assert %{description: "Description on Enum"} = type.values.foo
    end

    test "on Scalar" do
      type = Schema.__absinthe_type__(:on_scalar)

      assert %{description: "Description on Scalar"} = type
    end
  end
end
