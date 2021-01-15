defmodule Absinthe.Schema.Notation.Experimental.ImportFieldsTest do
  use Absinthe.Case, async: true
  import ExperimentalNotationHelpers

  @moduletag :experimental

  defmodule Source do
    use Absinthe.Schema.Notation

    object :source do
      field :one, :string do
      end

      field :two, :string do
      end

      field :three, :string do
      end
    end
  end

  defmodule WithoutOptions do
    use Absinthe.Schema.Notation

    object :internal_source do
      field :one, :string do
      end

      field :two, :string do
      end

      field :three, :string do
      end
    end

    object :internal_target do
      import_fields :internal_source
    end

    object :external_target do
      import_fields {Source, :source}
    end
  end

  defmodule UsingOnlyOption do
    use Absinthe.Schema.Notation

    object :internal_source do
      field :one, :string do
      end

      field :two, :string do
      end

      field :three, :string do
      end
    end

    object :internal_target do
      import_fields :internal_source, only: [:one, :two]
    end

    object :external_target do
      import_fields {Source, :source}, only: [:one, :two]
    end
  end

  defmodule UsingExceptOption do
    use Absinthe.Schema.Notation

    object :internal_source do
      field :one, :string do
      end

      field :two, :string do
      end

      field :three, :string do
      end
    end

    object :internal_target do
      import_fields :internal_source, except: [:one, :two]
    end

    object :external_target do
      import_fields {Source, :source}, except: [:one, :two]
    end
  end

  describe "import_fields" do
    test "without options from an internal source" do
      assert [{:internal_source, []}] == imports(WithoutOptions, :internal_target)
    end

    test "without options from an external source" do
      assert [{{Source, :source}, []}] == imports(WithoutOptions, :external_target)
    end

    test "with :only from an internal source" do
      assert [{:internal_source, only: [:one, :two]}] ==
               imports(UsingOnlyOption, :internal_target)
    end

    test "with :only from external source" do
      assert [{{Source, :source}, only: [:one, :two]}] ==
               imports(UsingOnlyOption, :external_target)
    end

    test "with :except from an internal source" do
      assert [{:internal_source, [except: [:one, :two]]}] ==
               imports(UsingExceptOption, :internal_target)
    end

    test "with :except from external source" do
      assert [{{Source, :source}, [except: [:one, :two]]}] ==
               imports(UsingExceptOption, :external_target)
    end
  end

  defp imports(module, type) do
    lookup_type(module, type).imports
  end
end
