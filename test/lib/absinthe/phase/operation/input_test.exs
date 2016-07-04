defmodule Absinthe.Phase.Operation.InputTest do
  use Absinthe.Case, async: true

  alias Absinthe.{Blueprint, Phase, Pipeline}

  @pre_pipeline [Phase.Parse, Phase.Blueprint]

  @query """
    query Foo($id: ID!) {
      foo(id: $id) {
        bar
      }
    }
    query Profile($age: Int = 36) {
      profile(name: "Bruce", age: $age) {
        id
      }
    }
  """

  describe "when not setting a required variable" do
    it "adds an error to the variable definition" do
      result = input(@query, "Foo", %{})
      op = result.operations |> Enum.find(&(&1.name == "Foo"))
      assert [%Blueprint.VariableDefinition{name: "id", errors: [%Phase.Error{message: "value not provided"}]}] = op.variable_definitions
    end
  end

  describe "when not providing a value for an optional variable with a default value" do
    it "uses the default value" do
      result = input(@query, "Profile", %{})
      op = result.operations |> Enum.find(&(&1.name == "Profile"))
      field = op.fields |> List.first
      age_argument = field.arguments |> Enum.find(&(&1.name == "age"))
      assert 36 == age_argument.provided_value
      name_argument = field.arguments |> Enum.find(&(&1.name == "name"))
      assert "Bruce" == name_argument.provided_value
    end
  end

  describe "when providing a value for an optional variable with a default value" do
    it "uses the default value" do
      result = input(@query, "Profile", %{"age" => 4})
      op = result.operations |> Enum.find(&(&1.name == "Profile"))
      field = op.fields |> List.first
      age_argument = field.arguments |> Enum.find(&(&1.name == "age"))
      assert 4 == age_argument.provided_value
      name_argument = field.arguments |> Enum.find(&(&1.name == "name"))
      assert "Bruce" == name_argument.provided_value
    end
  end

  def input(query, name, variables) do
    {:ok, result} = blueprint(query)
    |> Phase.Operation.Input.run(%{operation_name: name, variables: variables})

    result
  end

  defp blueprint(query) do
    {:ok, blueprint} = Pipeline.run(query, @pre_pipeline)
    blueprint
  end

end
