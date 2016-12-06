defmodule Absinthe.Schema.Notation.Experimental.ObjectTest do
  use Absinthe.Case
  import ExperimentalNotationHelpers

  defmodule Definition do
    use Absinthe.Schema.Notation.Experimental

    object :no_attrs do
    end

    object :with_attr, name: "Named" do
    end

  end

  describe "object" do
    describe "without attributes" do
      it "correctly builds the object definition" do
        assert %{name: "NoAttrs", identifier: :no_attrs} = lookup_type(Definition, :no_attrs)
      end
    end
    describe "with a name attribute" do
      it "correctly builds the object definition" do
        assert %{name: "Named", identifier: :with_attr} = lookup_type(Definition, :with_attr)
      end
    end

  end

end
