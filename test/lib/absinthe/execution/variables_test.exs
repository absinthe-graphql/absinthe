defmodule Absinthe.Execution.VariablesTest.Schema do
  use Absinthe.Schema

  input_object :contact_input do
    field :email, non_null(:string)
  end

  query do
    field :user, :string do
      arg :contact, non_null(:contact_input)

      resolve fn
        %{contact: %{email: email}}, _ ->
          {:ok, email}
        args, _ ->
          {:error, "got: #{inspect args}"}
      end
    end
  end
end

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
    parse(query_document, Things, provided)
  end
  def parse(query_document, schema, provided) do
    # Parse
    {:ok, document} = Absinthe.parse(query_document)
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
        processed: %{"id" => %Absinthe.Execution.Variable{value: @default, type_stack: ["String"]}}
      }} = @with_default |> parse
    end
  end

  describe "list variables" do
    it "should work in a basic case" do
      doc = """
      query FindContacts($contacts:[String]) {
        contacts(contacts:$contacts)
      }
      """
      assert %{variables: %Absinthe.Execution.Variables{
        processed: %{"contacts" => %Absinthe.Execution.Variable{value: value, type_stack: type}}
      }} = doc |> parse(%{"contacts" => ["ben", "bob"]})
      assert value == ["ben", "bob"]
      assert type == ["String", Absinthe.Type.List]
    end

    it "works when it's a list of input objects" do
      doc = """
      query FindContacts($contacts:[ContactInput]) {
        contacts(contacts:$contacts)
      }
      """
      assert %{variables: %Absinthe.Execution.Variables{
        processed: %{"contacts" => %Absinthe.Execution.Variable{value: value, type_stack: type}}
      }} = doc |> parse(__MODULE__.Schema, %{"contacts" => [%{"email" => "ben"}, %{"email" => "bob"}]})
      assert value == [%{email: "ben"}, %{email: "bob"}]
      assert type == ["ContactInput", Absinthe.Type.List]
    end
  end

  describe "input object variables" do
    it "should work in a basic case" do
      doc = """
      query FindContact($contact:ContactInput) {
        contact(contact:$contact)
      }
      """
      assert %{errors: errors, variables: %Absinthe.Execution.Variables{
        raw: %{},
        processed: %{"contact" => %Absinthe.Execution.Variable{value: value, type_stack: type}}
      }} = doc |> parse(__MODULE__.Schema, %{"contact" => %{"email" => "ben"}})
      assert errors == []
      assert %{email: "ben"} == value
      assert ["ContactInput"] == type
    end

    it "should return an error when a required field is explicitly set to nil" do
      doc = """
      query FindContact($contact:ContactInput) {
        contact(contact:$contact)
      }
      """
      assert %{errors: errors, variables: %Absinthe.Execution.Variables{
        raw: %{},
        processed: %{"contact" => %Absinthe.Execution.Variable{value: value, type_stack: type}}
      }} = doc |> parse(__MODULE__.Schema, %{"contact" => %{"email" => nil}})
      assert errors == [%{locations: [], message: "Variable `email' (email): Not provided"}]
      assert ["ContactInput"] == type
    end
  end

end
