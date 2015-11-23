defmodule ExGraphQL.Execution.VariablesTest do
  use ExSpec, async: true

  alias ExGraphQL.Execution

  @document """
    query FetchHumanQuery($id: Int!) {
      human(id: $id) {
        name
      }
    }
  """

  it "builds the variables from the AST" do
    {:ok, document} = ExGraphQL.parse(@document)
    schema = StarWars.Schema.schema
    {:ok, selected_op} = %Execution{schema: schema, document: document}
    |> Execution.categorize_definitions
    |> Execution.selected_operation
    assert {:ok, _} = Execution.Variables.build(schema, selected_op.variable_definitions, %{})
  end

end
