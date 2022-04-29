defmodule Absinthe.Schema.Notation.Experimental.ImportDirectivesTest do
  use Absinthe.Case, async: true

  @moduletag :experimental

  defmodule Source do
    use Absinthe.Schema.Notation

    directive :one do
      on [:field]
    end

    directive :two do
      on [:field]
    end

    directive :three do
      on [:field]
    end
  end

  defmodule WithoutOptions do
    use Absinthe.Schema

    query do
      field :foo, :string
    end

    import_directives Source
  end

  defmodule UsingOnlyOption do
    use Absinthe.Schema

    query do
      field :foo, :string
    end

    import_directives Source, only: [:one, :two]
  end

  defmodule UsingExceptOption do
    use Absinthe.Schema

    query do
      field :foo, :string
    end

    import_directives Source, except: [:one, :two]
  end

  describe "import_directives" do
    test "without options" do
      assert [{Source, []}] == imports(WithoutOptions)

      assert WithoutOptions.__absinthe_directive__(:one)
      assert WithoutOptions.__absinthe_directive__(:two)
      assert WithoutOptions.__absinthe_directive__(:three)
    end

    test "with :only" do
      assert [{Source, only: [:one, :two]}] == imports(UsingOnlyOption)

      assert UsingOnlyOption.__absinthe_directive__(:one)
      assert UsingOnlyOption.__absinthe_directive__(:two)
      refute UsingOnlyOption.__absinthe_directive__(:three)
    end

    test "with :except" do
      assert [{Source, except: [:one, :two]}] == imports(UsingExceptOption)

      refute UsingExceptOption.__absinthe_directive__(:one)
      refute UsingExceptOption.__absinthe_directive__(:two)
      assert UsingExceptOption.__absinthe_directive__(:three)
    end
  end

  defp imports(module) do
    %{schema_definitions: [schema]} = module.__absinthe_blueprint__()
    schema.directive_imports
  end
end
