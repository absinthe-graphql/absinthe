defmodule Absinthe.Phase.Schema.PrototypeTest do
  use Absinthe.Case, async: true

  alias Absinthe.{Blueprint, Phase, Pipeline, Type}

  @prototype_schema Support.Harness.Validation.Schema

  describe "Given a prototype schema" do
    it "sets the schema as the `:schema` field" do
      result = """
      type Foo @onObject {
        name: String
      }
      """
      |> run(@prototype_schema)
      IO.inspect(result)
    end
  end

  defp run(query, schema) do
    {:ok, result} = Absinthe.Pipeline.run(
      query,
      [
        Phase.Parse,
        Phase.Blueprint,
        {Phase.Schema.Prototype, [schema]}
      ]
    )
  end

end
