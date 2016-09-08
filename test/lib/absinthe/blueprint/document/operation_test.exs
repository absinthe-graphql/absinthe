defmodule Absinthe.Blueprint.Document.OperationTest do
  use Absinthe.Case, async: true

  alias Absinthe.{Blueprint, Pipeline, Phase}

  @query """
  query Foo($bar: String) {
    ... Baz
    other(arg: $not_defined) {
      name
    }
    ... {
      more(again: $more)
    }
  }
  fragment Baz on RootQueryType {
    name(bar: $bar) {
      thing
    }
  }
  fragment Other on RootQueryType {
    name(not_included: $bar) {
      baz
    }
    thing(other_not_included: $missing) {
      name
    }
  }
  """

  describe ".variables_used" do

    it "can determine the variables used" do
      result = run(@query)
      vars = Blueprint.Document.Operation.variables_used(operation_named(result, "Foo"), result)
      assert [
        %{name: "more"},
        %{name: "not_defined"},
        %{name: "bar"}
      ] = vars
    end

  end

  defp run(query) do
    {:ok, result} = Pipeline.run(query, [Phase.Parse, Phase.Blueprint])
    result
  end

  def operation_named(blueprint, name) do
    blueprint.operations
    |> Enum.find(&(&1.name == name))
  end

end
