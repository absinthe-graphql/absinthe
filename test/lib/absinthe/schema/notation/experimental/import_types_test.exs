defmodule Absinthe.Schema.Notation.Experimental.ImportTypesTest do
  use Absinthe.Case
  import ExperimentalNotationHelpers

  defmodule Source do
    use Absinthe.Schema.Notation.Experimental

    object :one do
    end
    object :two do
    end
    object :three do
    end

  end

  defmodule WithoutOptions do
    use Absinthe.Schema.Notation.Experimental

    import_types Source
  end

  defmodule UsingOnlyOption do
    use Absinthe.Schema.Notation.Experimental

    import_types Source, only: [:one, :two]
  end

  defmodule UsingExceptOption do
    use Absinthe.Schema.Notation.Experimental

    import_types Source, except: [:one, :two]
  end

  describe "import_types" do
    describe "without options" do
      it "imports the correct types" do
        assert 3 == type_count(WithoutOptions)
      end
    end
    describe "with :only" do
      it "imports the correct types" do
        assert 2 == type_count(UsingOnlyOption)
      end
    end
    describe "with :except" do
      it "imports the correct types" do
        assert 1 == type_count(UsingExceptOption)
      end
    end

  end

end
