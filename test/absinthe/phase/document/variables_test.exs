defmodule Absinthe.Phase.Document.VariablesTest do
  use Absinthe.Case, async: true

  alias Absinthe.{Blueprint, Phase, Pipeline}

  @pre_pipeline [Phase.Parse, Phase.Blueprint]

  @query """
    query Foo($id: ID!) {
      foo(id: $id) {
        bar
      }
    }
    query Profile($age: Int = 36, $name: String!) {
      profile(name: $name, age: $age) {
        id
      }
    }
  """

  describe "when not providing a value for an optional variable with a default value" do
    test "uses the default value" do
      result = input(@query, %{"name" => "Bruce"})
      op = result.operations |> Enum.find(&(&1.name == "Profile"))

      assert op.provided_values == %{
               "age" => %Blueprint.Input.Integer{
                 value: 36,
                 source_location: %Blueprint.SourceLocation{column: 29, line: 6}
               },
               "name" => %Blueprint.Input.String{value: "Bruce"}
             }
    end
  end

  describe "when providing an explicit null value for an optional variable with a default value" do
    test "uses null" do
      result = input(@query, %{"name" => "Bruce", "age" => nil})
      op = result.operations |> Enum.find(&(&1.name == "Profile"))

      assert op.provided_values == %{
               "age" => %Blueprint.Input.Null{},
               "name" => %Blueprint.Input.String{value: "Bruce"}
             }
    end
  end

  describe "when providing a value for an optional variable with a default value" do
    test "uses the default value" do
      result = input(@query, %{"age" => 4, "name" => "Bruce"})
      op = result.operations |> Enum.find(&(&1.name == "Profile"))

      assert op.provided_values == %{
               "age" => %Blueprint.Input.Integer{value: 4},
               "name" => %Blueprint.Input.String{value: "Bruce"}
             }
    end
  end

  test "should prevent using non input types as variables" do
    doc = """
    query Foo($input: Thing) {
      version
    }
    """

    expected = %{
      errors: [
        %{
          locations: [%{column: 11, line: 1}],
          message: "Variable \"input\" cannot be non-input type \"Thing\"."
        },
        %{
          locations: [%{column: 11, line: 1}, %{column: 1, line: 1}],
          message: "Variable \"input\" is never used in operation \"Foo\"."
        }
      ]
    }

    assert {:ok, expected} == Absinthe.run(doc, Absinthe.Fixtures.Things.MacroSchema)
  end

  def input(query, values) do
    {:ok, result} =
      blueprint(query)
      |> Phase.Document.Variables.run(variables: values)

    result
  end

  defp blueprint(query) do
    {:ok, blueprint, _} = Pipeline.run(query, @pre_pipeline)
    blueprint
  end
end
