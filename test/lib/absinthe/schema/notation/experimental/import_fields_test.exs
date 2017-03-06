defmodule Absinthe.Schema.Notation.Experimental.ImportFieldsTest do
  use Absinthe.Case
  import ExperimentalNotationHelpers

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
    describe "without options" do
      describe "from an internal source" do
        it "imports the correct fields" do
          assert 3 == length(lookup_type(WithoutOptions, :internal_target).fields)
        end
      end
      describe "from an external source" do
        it "imports the correct fields" do
          assert 3 == length(lookup_type(WithoutOptions, :external_target).fields)
        end
      end
    end
    describe "with :only" do
      describe "from an internal source" do
        it "imports the correct fields" do
          assert 2 == length(lookup_type(UsingOnlyOption, :internal_target).fields)
        end
      end
      describe "from external source" do
        it "imports the correct fields" do
          assert 2 == length(lookup_type(UsingOnlyOption, :external_target).fields)
        end
      end
    end
    describe "with :except" do
      describe "from an internal source" do
        it "imports the correct fields" do
          assert 1 == length(lookup_type(UsingExceptOption, :internal_target).fields)
        end
      end
      describe "from external source" do
        it "imports the correct fields" do
          assert 1 == length(lookup_type(UsingExceptOption, :external_target).fields)
        end
      end
    end

  end

end
