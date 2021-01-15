defmodule Absinthe.Schema.Notation.Experimental.ImportTypesTest do
  use Absinthe.Case, async: true

  @moduletag :experimental

  defmodule Source do
    use Absinthe.Schema.Notation

    object :one do
    end

    object :two do
    end

    object :three do
    end
  end

  defmodule WithoutOptions do
    use Absinthe.Schema

    query do
    end

    import_types Source
  end

  defmodule UsingOnlyOption do
    use Absinthe.Schema

    query do
    end

    import_types(Source, only: [:one, :two])
  end

  defmodule UsingExceptOption do
    use Absinthe.Schema

    query do
    end

    import_types(Source, except: [:one, :two])
  end

  describe "import_types" do
    test "without options" do
      assert [{Source, []}] == imports(WithoutOptions)

      assert WithoutOptions.__absinthe_type__(:one)
      assert WithoutOptions.__absinthe_type__(:two)
      assert WithoutOptions.__absinthe_type__(:three)
    end

    test "with :only" do
      assert [{Source, only: [:one, :two]}] == imports(UsingOnlyOption)

      assert UsingOnlyOption.__absinthe_type__(:one)
      assert UsingOnlyOption.__absinthe_type__(:two)
      refute UsingOnlyOption.__absinthe_type__(:three)
    end

    test "with :except" do
      assert [{Source, except: [:one, :two]}] == imports(UsingExceptOption)

      refute UsingExceptOption.__absinthe_type__(:one)
      refute UsingExceptOption.__absinthe_type__(:two)
      assert UsingExceptOption.__absinthe_type__(:three)
    end
  end

  defp imports(module) do
    %{schema_definitions: [schema]} = module.__absinthe_blueprint__
    schema.imports
  end
end
