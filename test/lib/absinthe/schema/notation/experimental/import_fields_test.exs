defmodule Absinthe.Schema.Notation.Experimental.ImportFieldsTest do
  use Absinthe.Case
  import ExperimentalNotationHelpers

  @moduletag :experimental

  defmodule Source do
    use Absinthe.Schema.Notation.Experimental

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
    use Absinthe.Schema.Notation.Experimental

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
    use Absinthe.Schema.Notation.Experimental

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
    use Absinthe.Schema.Notation.Experimental

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
      assert 3 == length(lookup_type(WithoutOptions, :internal_target).fields)
    end
    test "without options from an external source" do
      assert 3 == length(lookup_type(WithoutOptions, :external_target).fields)
    end
    test "with :only from an internal source" do
      assert 2 == length(lookup_type(UsingOnlyOption, :internal_target).fields)
    end
    test "with :only from external source" do
      assert 2 == length(lookup_type(UsingOnlyOption, :external_target).fields)
    end
    test "with :except from an internal source" do
      assert 1 == length(lookup_type(UsingExceptOption, :internal_target).fields)
    end
    test "with :except from external source" do
      assert 1 == length(lookup_type(UsingExceptOption, :external_target).fields)
    end
  end

end
