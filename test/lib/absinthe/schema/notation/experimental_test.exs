defmodule Absinthe.Schema.Notation.ExperimentalTest do
  use Absinthe.Case

  defmodule Schema do
    use Absinthe.Schema.Notation.Experimental

    object :foo do
      field :bar, :string do
        resolve fn _, _, _ -> {:ok, 1} end
      end
    end

    defp foo(_, _, _) do
      {:ok, 1}
    end

  end


  defmodule ChildSchema do
    use Absinthe.Schema.Notation.Experimental

    import_types Schema

    object :baz do
      import_fields :foo
    end

  end

  defmodule OtherSchema do
    use Absinthe.Schema.Notation.Experimental

    object :quux do
      import_fields {ChildSchema, :baz}
    end

  end

  alias Absinthe.Blueprint

  describe "object" do
    it "adds a blueprint object" do
      assert %Blueprint{types: [%Blueprint.Schema.ObjectTypeDefinition{name: "Foo", identifier: :foo, fields: [%Blueprint.Schema.FieldDefinition{name: "bar", identifier: :bar, type: :string}]}]} = Schema.__absinthe_blueprint__()
    end
    it "adds field attributes" do
      %Blueprint{types: [%{fields: [%{resolve_ast: resolver_ast}]}]} = Schema.__absinthe_blueprint__()
      assert is_tuple(resolver_ast)
    end
  end

  describe "import_types" do
    it "merges types" do
      assert 2 == length(ChildSchema.__absinthe_blueprint__().types)
    end
  end

  describe "import_fields" do
    it "merges fields from other types by identifier" do
      type = Blueprint.Schema.lookup_type(ChildSchema.__absinthe_blueprint__(), :baz)
      assert [%{identifier: :bar}] = type.fields
    end
    it "merges fields from other types by module and identifier" do
      type = Blueprint.Schema.lookup_type(OtherSchema.__absinthe_blueprint__(), :quux)
      assert [%{identifier: :bar}] = type.fields
    end

  end

end
