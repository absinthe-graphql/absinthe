defmodule ExGraphQL.Execution.VariablesTest do
  use ExSpec, async: true

  alias ExGraphQL.Execution

  @id_required """
    query FetchHumanQuery($id: String!) {
      human(id: $id) {
        name
      }
    }
    """

  @with_default """
    query FetchHumanQuery($id: String = "1000") {
      human(id: $id) {
        name
      }
    }
  """

  it "supports required variables" do
    {:ok, document} = ExGraphQL.parse(@id_required)
    schema = StarWars.Schema.schema
    {:ok, selected_op} = %Execution{schema: schema, document: document}
    |> Execution.categorize_definitions
    |> Execution.selected_operation
    # Provided
    assert {:ok, %{"id" => "2000"}} = Execution.Variables.build(schema, selected_op.variable_definitions, %{"id" => 2000})
    # Not provided
    assert {:error, %{"id" => _}} = Execution.Variables.build(schema, selected_op.variable_definitions, %{})
  end

  it "supports variable defaults" do
    {:ok, document} = ExGraphQL.parse(@with_default)
    schema = StarWars.Schema.schema
    {:ok, selected_op} = %Execution{schema: schema, document: document}
    |> Execution.categorize_definitions
    |> Execution.selected_operation
    # Provided variable
    assert {:ok, %{"id" => "2000"}} = Execution.Variables.build(schema, selected_op.variable_definitions, %{"id" => "2000"})
    # Using default
    assert {:ok, %{"id" => "1000"}} = Execution.Variables.build(schema, selected_op.variable_definitions, %{})

  end


end
