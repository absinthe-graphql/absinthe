defmodule Absinthe.Schema.Notation.Experimental.FieldTest do
  use Absinthe.Case, async: true
  import ExperimentalNotationHelpers

  @moduletag :experimental

  defmodule Definition do
    use Absinthe.Schema.Notation

    @desc "Object description"
    object :obj do
      field :plain, :string

      field :with_block, :string do
      end

      field :with_attrs, type: :boolean, name: "HasAttrs"

      field :with_attrs_and_body, type: :boolean, name: "HasAttrsAndBody" do
      end

      @desc "Desc One"
      field :with_desc, :string

      @desc "Desc Two"
      field :with_desc_and_block, :string do
      end

      @desc "Desc Three"
      field :with_desc_attr, type: :string, description: "overridden"

      field :with_desc_attr_literal, type: :string, description: "Desc Four"

      @desc "Desc Five"
      field :with_desc_attr_mod, type: :string, description: @desc_five
    end
  end

  describe "field" do
    test "without a body and with a bare type" do
      assert %{name: "plain", description: nil, type: :string, identifier: :plain} =
               lookup_field(Definition, :obj, :plain)
    end

    test "with a body and with a bare type" do
      assert %{name: "with_block", type: :string, identifier: :with_block} =
               lookup_field(Definition, :obj, :with_block)
    end

    test "with attrs and without a body" do
      assert %{name: "HasAttrs", type: :boolean, identifier: :with_attrs} =
               lookup_field(Definition, :obj, :with_attrs)
    end

    test "with attrs and with a body" do
      assert %{name: "HasAttrsAndBody", type: :boolean, identifier: :with_attrs_and_body} =
               lookup_field(Definition, :obj, :with_attrs_and_body)
    end

    test "with @desc and without a block" do
      assert %{description: "Desc One"} = lookup_field(Definition, :obj, :with_desc)
    end

    test "with @desc and with a block" do
      assert %{description: "Desc Two"} = lookup_field(Definition, :obj, :with_desc_and_block)
    end

    test "with @desc and a description attr" do
      assert %{description: "Desc Three"} = lookup_field(Definition, :obj, :with_desc_attr)
    end

    test "with a description attribute as a literal" do
      assert %{description: "Desc Four"} = lookup_field(Definition, :obj, :with_desc_attr_literal)
    end

    test "with a description attribute from a module attribute" do
      assert %{description: "Desc Five"} = lookup_field(Definition, :obj, :with_desc_attr_mod)
    end
  end
end
