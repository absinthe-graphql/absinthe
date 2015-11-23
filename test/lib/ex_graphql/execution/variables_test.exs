defmodule ExGraphQL.Execution.VariablesTest do
  use ExSpec, async: true

  alias ExGraphQL.Execution

  @document """
    query FetchHumanQuery($id: String!) {
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
    assert {:ok, %{"id" => "2000"}} = Execution.Variables.build(schema, selected_op.variable_definitions, %{"id" => 2000})
  end

end
