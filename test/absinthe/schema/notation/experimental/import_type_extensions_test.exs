defmodule Absinthe.Schema.Notation.Experimental.ImportTypeExtensionsTest do
  use Absinthe.Case, async: true

  @moduletag :experimental

  defmodule Source do
    use Absinthe.Schema.Notation

    extend object(:one) do
      field :one, :string
    end

    extend object(:two) do
      field :two, :string
    end

    extend object(:three) do
      field :three, :string
    end
  end

  defmodule WithoutOptions do
    use Absinthe.Schema

    query do
      field :foo, :string
    end

    object :one do
    end

    object :two do
    end

    object :three do
    end

    import_type_extensions Source
  end

  defmodule UsingOnlyOption do
    use Absinthe.Schema

    query do
      field :foo, :string
    end

    object :one do
    end

    object :two do
    end

    object :three do
      field :foo, :string
    end

    import_type_extensions Source, only: [:one, :two]
  end

  defmodule UsingExceptOption do
    use Absinthe.Schema

    query do
      field :foo, :string
    end

    object :one do
      field :foo, :string
    end

    object :two do
      field :foo, :string
    end

    object :three do
    end

    import_type_extensions Source, except: [:one, :two]
  end

  describe "import_types" do
    test "without options" do
      assert [{Source, []}] == imports(WithoutOptions)

      assert [%{identifier: :one}] = fields(WithoutOptions, :one)
      assert [%{identifier: :two}] = fields(WithoutOptions, :two)
      assert [%{identifier: :three}] = fields(WithoutOptions, :three)
    end

    test "with :only" do
      assert [{Source, only: [:one, :two]}] == imports(UsingOnlyOption)

      assert [%{identifier: :one}] = fields(UsingOnlyOption, :one)
      assert [%{identifier: :two}] = fields(UsingOnlyOption, :two)
      assert [%{identifier: :foo}] = fields(UsingOnlyOption, :three)
    end

    test "with :except" do
      assert [{Source, except: [:one, :two]}] == imports(UsingExceptOption)

      assert [%{identifier: :foo}] = fields(UsingExceptOption, :one)
      assert [%{identifier: :foo}] = fields(UsingExceptOption, :two)
      assert [%{identifier: :three}] = fields(UsingExceptOption, :three)
    end
  end

  defp imports(module) do
    %{schema_definitions: [schema]} = module.__absinthe_blueprint__()
    schema.type_extension_imports
  end

  defp fields(module, type) do
    module.__absinthe_type__(type).fields
    |> Map.values()
    |> Enum.reject(&match?(%{identifier: :__typename}, &1))
  end
end
