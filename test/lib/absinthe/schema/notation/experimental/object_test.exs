defmodule Absinthe.Schema.Notation.Experimental.ObjectTest do
  use Absinthe.Case
  import ExperimentalNotationHelpers

  defmodule Definition do
    use Absinthe.Schema.Notation.Experimental

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

    @desc_five "Desc Five"
    object :with_desc_attr_mod, description: @desc_five do
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
    describe "with a @desc" do
      describe "and no description attr" do
        it "correctly builds the object definition" do
          assert %{description: "Desc One"} = lookup_type(Definition, :with_desc)
        end
      end
      describe "using an assignment" do
        it "correctly builds the object definition" do
          assert %{description: "Desc Three"} = lookup_type(Definition, :with_desc_assign)
        end
      end

      describe "and a description attr" do
        it "overrides the description attr" do
          assert %{description: "Desc Two"} = lookup_type(Definition, :with_desc_attr)
        end
      end
    end
    describe "with a description attribute" do
      describe "as a literal" do
        it "correctly builds the object definition" do
          assert %{description: "Desc Four"} = lookup_type(Definition, :with_desc_attr_literal)
        end
      end
      describe "from a module attribute" do
        it "correctly builds the object definition" do
          assert %{description: "Desc Five"} = lookup_type(Definition, :with_desc_attr_mod)
        end
      end
    end
  end

end
