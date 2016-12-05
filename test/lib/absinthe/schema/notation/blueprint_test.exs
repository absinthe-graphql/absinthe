defmodule Absinthe.Schema.Notation.BlueprintTest do
  use Absinthe.Case

  defmodule Schema do
    use Absinthe.Schema.Notation.Blueprint

    object :foo do
      field :bar, :string do
      end
    end

  end

  alias Absinthe.Blueprint

  describe "object" do
    it "adds a blueprint object" do
      assert %Blueprint{types: [%Blueprint.Schema.ObjectTypeDefinition{name: "Foo", identifier: :foo, fields: [%Blueprint.Schema.FieldDefinition{name: "bar", identifier: :bar, type: :string}]}]} = Schema.__absinthe_blueprint__
    end
  end


end
