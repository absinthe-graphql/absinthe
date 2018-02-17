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
    test "without options" do
      assert 3 == type_count(WithoutOptions)
    end
    test "with :only" do
      assert 2 == type_count(UsingOnlyOption)
    end
    test "with :except" do
      assert 1 == type_count(UsingExceptOption)
    end
  end

end
