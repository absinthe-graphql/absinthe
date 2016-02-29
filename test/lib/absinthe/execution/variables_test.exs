defmodule Absinthe.Execution.VariablesTest do
  use ExSpec, async: true

  alias Absinthe.Execution

  @id_required """
    query FetchThingQuery($id: String!) {
      thing(id: $id) {
        name
      }
    }
    """

  @default "foo"
  @with_default """
    query FetchThingQuery($id: String = "#{@default}") {
      thing(id: $id) {
        name
      }
    }
    """

  def parse(query_document, provided \\ %{}) do
    # Parse
    {:ok, document} = Absinthe.parse(query_document)
    # Get schema
    schema = Things
    # Prepare execution context
    {:ok, execution} = %Execution{schema: schema, document: document, variables: provided}
    |> Execution.prepare
    execution
  end

  describe "a required variable" do

    context "when provided" do

      it "returns a value" do
        provided = %{"id" => "foo"}
        assert %{variables: %{"id" => "foo"}} = @id_required |> parse(provided)
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
      provided = %{"id" => "bar"}
      assert %{variables: %{"id" => "bar"}} = @with_default |> parse(provided)
    end

    it "when not provided" do
      assert %{variables: %{"id" => @default}} = @with_default |> parse
    end

  end

end
