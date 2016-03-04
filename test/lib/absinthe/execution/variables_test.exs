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
    {:ok, execution} = %Execution{schema: schema, document: document}
    |> Execution.prepare(%{variables: provided})
    execution
  end

  describe "a required variable" do

    context "when provided" do

      it "returns a value" do
        provided = %{"id" => "foo"}
        assert %{variables: %Absinthe.Execution.Variables{
          raw: %{"id" => "foo"},
          processed: %{"id" => %Absinthe.Execution.Variable{value: "foo"}}
        }} = @id_required |> parse(provided)

      end

    end

    context "when not provided" do

      it "returns an error" do
        assert %{variables: %Absinthe.Execution.Variables{raw: %{}}, errors: [%{message: "Variable `id' (String): Not provided"}]} = @id_required |> parse
        assert {:ok, %{data: %{}, errors: [%{locations: [%{column: 0, line: 1}], message: "Variable `id' (String): Not provided"}]}} == Absinthe.run(@id_required, Things)
      end

    end

  end

  describe "a defaulted variable" do

    it "when provided" do
      provided = %{"id" => "bar"}
      assert %{variables: %Absinthe.Execution.Variables{
        raw: %{"id" => "bar"},
        processed: %{"id" => %Absinthe.Execution.Variable{value: "bar"}}
      }} = @with_default |> parse(provided)
    end

    it "when not provided" do
      assert %{variables: %Absinthe.Execution.Variables{
        raw: %{},
        processed: %{"id" => %Absinthe.Execution.Variable{value: @default, type_name: "String"}}
      }} = @with_default |> parse
    end

  end

end
