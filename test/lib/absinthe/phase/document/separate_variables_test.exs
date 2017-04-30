defmodule Absinthe.Phase.Document.VariablesTest do
  use ExUnit.Case, async: true

  defmodule Schema do
    use Absinthe.Schema

    query do
      field :version, :string do
        arg :string, :version
      end
    end
  end

  alias Absinthe.Blueprint
  alias Absinthe.Blueprint.Document.VariableDefinition

  test "we can validate variables separately" do
    value = "Hello World" |> Blueprint.Input.parse
    input = %Blueprint.Input.Value{normalized: value}
    definition = build("input", "String", %{input: input})

    validation_pipeline = Absinthe.Pipeline.for_variables(Schema)
  end

  defp build(name, type, opts \\ %{}) do
    %VariableDefinition{
      name: name,
      type: %Absinthe.Blueprint.TypeReference.Name{errors: [],
       name: type, schema_node: Absinthe.Schema.lookup_type(Schema, type)}
    }
    |> Map.merge(opts)
  end
end
