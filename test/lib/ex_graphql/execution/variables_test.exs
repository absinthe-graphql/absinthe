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
    {:ok, selected_op} = %Execution{schema: schema, document: document}
    |> Execution.categorize_definitions
    |> Execution.selected_operation
    # Build variable map
    Execution.Variables.build(
      schema,
      selected_op.variable_definitions,
      provided
    )
  end

  describe "a required variable" do

    context "when provided" do

      it "returns a value" do
        provided = %{"id" => "2000"}
        assert {:ok, %{"id" => "2000"}} = @id_required |> variables(provided)
      end

    end

    context "when not provided" do

      it "returns an error" do
        assert {:error, %{"id" => "can not be missing"}} = @id_required |> variables
      end

    end

  end

  describe "a defaulted variable" do

    it "when provided" do
      provided = %{"id" => "2000"}
      assert {:ok, %{"id" => "2000"}} = @with_default |> variables(provided)
    end

    it "when not provided" do
      assert {:ok, %{"id" => @default}} = @with_default |> variables
    end

  end

end
