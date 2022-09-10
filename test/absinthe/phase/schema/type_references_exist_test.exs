defmodule Absinthe.Schema.Validation.TypeReferencesExistTest do
  use Absinthe.Case, async: true

  describe "fields" do
    @schema ~S{
  defmodule FieldSchema do
    use Absinthe.Schema

    query do
      field :foo, :string
      field :bar, non_null(:string)
      field :baz, :qux
    end
  end
  }

    test "errors unknown type reference" do
      error = ~r/In field Baz, :qux is not defined in your schema./

      assert_raise(Absinthe.Schema.Error, error, fn ->
        Code.eval_string(@schema, [], __ENV__)
      end)
    end
  end

  describe "objects" do
    @schema ~S{
    defmodule ObjectImportSchema do
      use Absinthe.Schema

      query do
        field :foo, :string
      end

      object :baz do
        field :name, :string
      end

      object :bar do
        import_fields non_null(:baz)
      end
    end
    }
    test "errors on import_fields with wrapped type" do
      error = ~r/In object Bar, cannot accept a non-null or a list type.\n\nGot: Baz!/

      assert_raise(Absinthe.Schema.Error, error, fn ->
        Code.eval_string(@schema, [], __ENV__)
      end)
    end

    @schema ~S{
    defmodule ObjectInterfaceSchema do
      use Absinthe.Schema

      query do
        field :foo, :string
      end

      object :baz do
        field :name, :string
      end

      object :qux do
        interface list_of(:baz)
      end
    end
    }
    test "errors on interface with wrapped type" do
      error = ~r/In object Qux, cannot accept a non-null or a list type./

      assert_raise(Absinthe.Schema.Error, error, fn ->
        Code.eval_string(@schema, [], __ENV__)
      end)
    end
  end

  describe "interface" do
    @schema ~S{
    defmodule InterfaceSchema do
      use Absinthe.Schema

      query do
        field :foo, :string
      end

      interface :qux do
        interface list_of(:baz)
      end
    end
    }
    test "errors on interface with wrapped type" do
      error = ~r/In interface Qux, cannot accept a non-null or a list type./

      assert_raise(Absinthe.Schema.Error, error, fn ->
        Code.eval_string(@schema, [], __ENV__)
      end)
    end
  end

  describe "input object" do
    @schema ~S{
    defmodule InputObjectSchema do
      use Absinthe.Schema

      query do
        field :foo, :string
      end

      input_object :bar do
        import_fields non_null(:baz)
      end
    end
    }
    test "errors on import_fields with wrapped type" do
      error = ~r/In input object Bar, cannot accept a non-null or a list type.\n\nGot: Baz!/

      assert_raise(Absinthe.Schema.Error, error, fn ->
        Code.eval_string(@schema, [], __ENV__)
      end)
    end
  end

  describe "union type" do
    @schema ~S{
    defmodule UnionSchema do
      use Absinthe.Schema

      query do
        field :foo, :string
      end

      union :bar do
        types [list_of(:baz)]
      end

    end
    }
    test "errors on types with wrapped type" do
      error = ~r/In union Bar, cannot accept a non-null or a list type./

      assert_raise(Absinthe.Schema.Error, error, fn ->
        Code.eval_string(@schema, [], __ENV__)
      end)
    end
  end
end
