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

  def parse(query_document, provided \\ %{}) do
    # Parse
    {:ok, document} = ExGraphQL.parse(query_document)
    # Get schema
    schema = StarWars.Schema.schema
    # Prepare execution context
    {:ok, execution} = %Execution{schema: schema, document: document, variables: provided}
    |> Execution.prepare
    execution
  end

  describe "a required variable" do

    context "when provided" do

      it "returns a value" do
        provided = %{"id" => "2000"}
        assert %{variables: %{"id" => "2000"}, errors: []} = @id_required |> parse(provided)
      end

    end

    context "when not provided" do

      it "returns an error" do
        assert %{variables: %{}, errors: [%{message: "Variable `id' (String): Not provided"}]} = @id_required |> parse
      end

    end

  end

  describe "a defaulted variable" do

    it "when provided" do
      provided = %{"id" => "2000"}
      assert %{variables: %{"id" => "2000"}, errors: []} = @with_default |> parse(provided)
    end

    it "when not provided" do
      assert %{variables: %{"id" => @default}, errors: []} = @with_default |> parse
    end

  end

end
