defmodule Absinthe.Schema.Notation.Experimental.ArgumentTest do
  use Absinthe.Case, async: true
  import ExperimentalNotationHelpers

  @moduletag :experimental

  defmodule Definition do
    use Absinthe.Schema.Notation

    @desc "Object"
    object :obj do
      @desc "Field"
      field :field, :string do
        arg :plain, :string

        arg :with_attrs, type: :boolean, name: "HasAttrs"

        @desc "Desc One"
        arg :with_desc, :string

        @desc "Desc Three"
        arg :with_desc_attr, type: :string, description: "overridden"

        arg :with_desc_attr_literal, type: :string, description: "Desc Four"
      end
    end
  end

  describe "arg" do
    test "with a bare type" do
      assert %{name: "plain", description: nil, type: :string, identifier: :plain} =
               lookup_argument(Definition, :obj, :field, :plain)
    end

    test "with attrs" do
      assert %{name: "HasAttrs", type: :boolean, identifier: :with_attrs} =
               lookup_argument(Definition, :obj, :field, :with_attrs)
    end

    test "with @desc" do
      assert %{description: "Desc One"} = lookup_argument(Definition, :obj, :field, :with_desc)
    end

    test "with @desc and a description attr" do
      assert %{description: "Desc Three"} =
               lookup_argument(Definition, :obj, :field, :with_desc_attr)
    end

    test "with a description attribute as a literal" do
      assert %{description: "Desc Four"} =
               lookup_argument(Definition, :obj, :field, :with_desc_attr_literal)
    end
  end
end
