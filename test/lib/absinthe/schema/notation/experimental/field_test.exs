defmodule Absinthe.Schema.Notation.Experimental.FieldTest do
  use Absinthe.Case
  import ExperimentalNotationHelpers

  defmodule Definition do
    use Absinthe.Schema.Notation.Experimental

    object :obj do
      field :plain, :string
      field :with_block, :string do
      end
      field :with_attrs, type: :boolean, name: "HasAttrs"
      field :with_attrs_and_body, type: :boolean, name: "HasAttrsAndBody" do
      end
    end

  end

  describe "field" do
    describe "without a body and with a bare type" do
      it "correctly builds the field definition" do
        assert %{name: "plain", type: :string, identifier: :plain} = lookup_field(Definition, :obj, :plain)
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


  end

end
