defmodule Absinthe.Schema.Notation.DirectiveTest do
  use Absinthe.Case, async: true

  defmodule SchemaPrototype do
    use Absinthe.Schema.Prototype

    directive :feature do
      arg :name, non_null(:string)
      on [:field_definition]
    end

    directive :camelCase do
      on [:object]
    end
  end

  defmodule SchemaTest do
    use Absinthe.Schema

    @prototype_schema SchemaPrototype

    object :person do
      directive :camelCase

      field :name, non_null(:string), directives: [feature: [name: "some_name"]]
    end

    query do
      field :lookup_person, :person, resolve: fn _, _ ->
        {:ok, %{name: "Beyonce"}}
      end
    end
  end
  
  test "cameCased directive is present on schema" do
    assert SchemaTest.__absinthe_directive__(:camelCase)
  end
end