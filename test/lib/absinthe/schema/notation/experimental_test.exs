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


end
