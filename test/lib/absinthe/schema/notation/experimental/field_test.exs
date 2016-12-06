defmodule Absinthe.Schema.Notation.Experimental.FieldTest do
  use Absinthe.Case
  import ExperimentalNotationHelpers

  defmodule Definition do
    use Absinthe.Schema.Notation.Experimental

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

      @desc_five "Desc Five"
      field :with_desc_attr_mod, type: :string, description: @desc_five

    end

  end

  describe "field" do
    describe "without a body and with a bare type" do
      it "correctly builds the field definition" do
        assert %{name: "plain", description: nil, type: :string, identifier: :plain} = lookup_field(Definition, :obj, :plain)
      end
    end
    describe "with a body and with a bare type" do
      it "correctly builds the field definition" do
        assert %{name: "withBlock", type: :string, identifier: :with_block} = lookup_field(Definition, :obj, :with_block)
      end
    end
    describe "with attrs" do
      describe "and without a body" do
        it "correctly builds the field definition" do
          assert %{name: "HasAttrs", type: :boolean, identifier: :with_attrs} = lookup_field(Definition, :obj, :with_attrs)
        end
      end
      describe "and with a body" do
        it "correctly builds the field definition" do
          assert %{name: "HasAttrsAndBody", type: :boolean, identifier: :with_attrs_and_body} = lookup_field(Definition, :obj, :with_attrs_and_body)
        end
      end
    end
    describe "with @desc" do
      describe "and without a block" do
        it "correctly builds the field definition" do
          assert %{description: "Desc One"} = lookup_field(Definition, :obj, :with_desc)
        end
      end
      describe "and with a block" do
        it "correctly builds the field definition" do
          assert %{description: "Desc Two"} = lookup_field(Definition, :obj, :with_desc_and_block)
        end
      end
      describe "and a description attr" do
        it "overrides the description attr" do
          assert %{description: "Desc Three"} = lookup_field(Definition, :obj, :with_desc_attr)
        end
      end
    end
    describe "with a description attribute" do
      describe "as a literal" do
        it "correctly builds the field definition" do
          assert %{description: "Desc Four"} = lookup_field(Definition, :obj, :with_desc_attr_literal)
        end
      end
      describe "from a module attribute" do
        it "correctly builds the field definition" do
          assert %{description: "Desc Five"} = lookup_field(Definition, :obj, :with_desc_attr_mod)
        end
      end
    end

  end

end
