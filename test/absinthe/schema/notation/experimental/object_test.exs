defmodule Absinthe.Schema.Notation.Experimental.ObjectTest do
  use Absinthe.Case, async: true
  import ExperimentalNotationHelpers

  @moduletag :experimental

  defmodule Definition do
    use Absinthe.Schema.Notation

    object :no_attrs do
    end

    object :with_attr, name: "Named" do
    end

    @desc "Desc One"
    object :with_desc do
    end

    @desc "Desc Two"
    object :with_desc_attr, description: "overridden" do
    end

    @modattr "Desc Three"
    @desc @modattr
    object :with_desc_assign do
    end

    object :with_desc_attr_literal, description: "Desc Four" do
    end

    @desc "Desc Five"
    object :with_desc_attr_mod, description: @desc_five do
    end
  end

  describe "object" do
    test "without attributes" do
      assert %{name: "NoAttrs", identifier: :no_attrs} = lookup_type(Definition, :no_attrs)
    end

    test "with a name attribute" do
      assert %{name: "Named", identifier: :with_attr} = lookup_type(Definition, :with_attr)
    end

    test "with a @desc and no description attr" do
      assert %{description: "Desc One"} = lookup_type(Definition, :with_desc)
    end

    test "with a @desc using an assignment" do
      assert %{description: "Desc Three"} = lookup_type(Definition, :with_desc_assign)
    end

    test "with a @desc and a description attr" do
      assert %{description: "Desc Two"} = lookup_type(Definition, :with_desc_attr)
    end

    test "with a description attribute as a literal" do
      assert %{description: "Desc Four"} = lookup_type(Definition, :with_desc_attr_literal)
    end

    test "from a module attribute" do
      assert %{description: "Desc Five"} = lookup_type(Definition, :with_desc_attr_mod)
    end
  end
end
