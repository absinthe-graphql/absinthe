defmodule Absinthe.Phase.Document.ArgumentsTest do
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

  describe "when not providing a value for an optional variable with a default value" do
    it "uses the default value" do
      result = input(@query, %{})
      op = result.operations |> Enum.find(&(&1.name == "Profile"))
      field = op.selections |> List.first
      age_argument = field.arguments |> Enum.find(&(&1.name == "age"))
      assert %Blueprint.Input.Integer{value: 36} == age_argument.provided_value
      name_argument = field.arguments |> Enum.find(&(&1.name == "name"))
      assert %Blueprint.Input.String{value: "Bruce"} == name_argument.provided_value
    end
  end

  describe "when providing a value for an optional variable with a default value" do
    it "uses the default value" do
      result = input(@query, %{"age" => 4})
      op = result.operations |> Enum.find(&(&1.name == "Profile"))
      field = op.selections |> List.first
      age_argument = field.arguments |> Enum.find(&(&1.name == "age"))
      assert %Blueprint.Input.Integer{value: 4} == age_argument.provided_value
      name_argument = field.arguments |> Enum.find(&(&1.name == "name"))
      assert %Blueprint.Input.String{value: "Bruce"} == name_argument.provided_value
    end
  end

  def input(query, values) do
    {:ok, result} = blueprint(query, values)
    |> Phase.Document.Arguments.run([])

    result
  end

  defp blueprint(query, values) do
    {:ok, blueprint} = Pipeline.run(query, @pre_pipeline ++ [{Phase.Document.Variables, values: values}])
    blueprint
  end

end
