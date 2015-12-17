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

  @default "1000"
  @with_default """
    query FetchHumanQuery($id: String = "#{@default}") {
      human(id: $id) {
        name
      }
    }
    """

  def variables(query_document, provided \\ %{}) do
    # Parse
    {:ok, document} = ExGraphQL.parse(query_document)
    # Get schema
    schema = StarWars.Schema.schema
    # Prepare execution context
    execution = %Execution{schema: schema, document: document}
    |> Execution.categorize_definitions
    |> Execution.add_configured_adapter
    {:ok, selected_op} = Execution.selected_operation(execution)
    # Build variable map
    Execution.Variables.build(
      execution,
      selected_op.variable_definitions,
      provided
    )
  end

  describe "a required variable" do

    context "when provided" do

      it "returns a value" do
        provided = %{"id" => "2000"}
        assert %{values: %{"id" => "2000"}, errors: []} = @id_required |> variables(provided)
      end

    end

    context "when not provided" do

      it "returns an error" do
        assert %{values: %{}, errors: [%{message: "Variable `id' (String): Not provided"}]} = @id_required |> variables
      end

    end

  end

  describe "a defaulted variable" do

    it "when provided" do
      provided = %{"id" => "2000"}
      assert %{values: %{"id" => "2000"}, errors: []} = @with_default |> variables(provided)
    end

    it "when not provided" do
      assert %{values: %{"id" => @default}, errors: []} = @with_default |> variables
    end

  end

end
