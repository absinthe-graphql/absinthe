defmodule Absinthe.Execution.VariablesTest.Schema do
  use Absinthe.Schema

  input_object :contact_input do
    field :email_value, non_null(:string)
    field :address, non_null(:string), deprecate: "no longer used"
    field :addresses, list_of(:string)
  end

  input_object :nullable_input do
    field :field1, :string
    field :field2, :string
    field :contact, :contact_input
  end

  query do
    field :nullable, :string do
      arg :thing, :string
      arg :input, :nullable_input

      resolve fn
        %{thing: thing}, _ ->
          {:ok, "Got #{inspect thing}"}
        %{input: fields}, _ ->
          {:ok, "Got #{inspect Map.keys(fields)}"}
        _, _ ->
          {:ok, "Got nothing"}
        end
    end

    field :contacts, :string do
      arg :contacts, non_null(list_of(non_null(:contact_input)))

      resolve fn
        %{contacts: _}, _ ->
          {:ok, "we did it"}
        args, _ ->
          {:error, "got: #{inspect args}"}
      end
    end

    field :user, :string do
      arg :contact, non_null(:contact_input)

      resolve fn
        %{contact: %{email_value: email}}, _ ->
          {:ok, email}
        args, _ ->
          {:error, "got: #{inspect args}"}
      end
    end
  end
end

defmodule Absinthe.Execution.VariablesTest do
  use Absinthe.Case, async: true

  alias Absinthe.Execution

  def parse(query_document, provided \\ %{}) do
    parse(query_document, Things, provided)
  end
  def parse(query_document, schema, provided) do
    # Parse
    {:ok, document} = Absinthe.parse(query_document)
    # Prepare execution context
    {_, execution} = %Execution{schema: schema, document: document}
    |> Execution.prepare(%{variables: provided})

    Execution.Variables.build(execution)
  end

  describe "a required variable" do
    @id_required """
      query FetchThingQuery($id: String!) {
        thing(id: $id) {
          name
        }
      }
      """
    context "when provided" do

      it "returns a value" do
        provided = %{"id" => "foo"}
        assert {:ok, %{variables: %Absinthe.Execution.Variables{
          raw: %{"id" => "foo"},
          processed: %{"id" => %Absinthe.Execution.Variable{value: "foo"}}
        }}} = @id_required |> parse(provided)
      end
    end

    context "when not provided" do
      it "returns an error" do
        assert {:error, %{variables: %Absinthe.Execution.Variables{raw: %{}}, errors: errors}} = @id_required |> parse
        assert [%{locations: [%{column: 0, line: 1}], message: "Variable `id' (String): Not provided"}] == errors
        assert {:ok, %{errors: [%{locations: [%{column: 0, line: 1}], message: "Variable `id' (String): Not provided"}]}} = Absinthe.run(@id_required, Things)
      end
    end
  end

  describe "scalar variable" do
    it "returns an error if it does not parse" do
      doc = """
      query ScalarError($item:Int){foo(bar:$item)}
      """
      assert {:error, %{errors: errors}} = doc |> parse(%{"item" => "asdf"})
      assert [%{locations: [%{column: 0, line: 1}], message: "Variable `item' (Int): Invalid value provided"}] == errors
    end
  end

  describe "a defaulted variable" do
    @default "foo"
    @with_default """
    query FetchThingQuery($id: String = "#{@default}") {
      thing(id: $id) {
        name
      }
    }
    """
    it "when provided" do
      provided = %{"id" => "bar"}
      assert {:ok, %{variables: %Absinthe.Execution.Variables{
        raw: %{"id" => "bar"},
        processed: %{"id" => %Absinthe.Execution.Variable{value: "bar"}}
      }}} = @with_default |> parse(provided)
    end

    it "when not provided" do
      assert {:ok, %{variables: %Absinthe.Execution.Variables{
        raw: %{},
        processed: %{"id" => %Absinthe.Execution.Variable{value: @default, type_stack: ["String"]}}
      }}} = @with_default |> parse
    end
  end

  describe "duplicate variable name" do
    it "returns an error if a variable is duplicated" do
      doc = """
      query DuplicateError($item: Int, $item: Int) {
        foo(bar: $item) { baz }
      }
      """
      assert {:error, %{errors: errors}} = doc |> parse(%{"item" => 1})
      assert [%{locations: [%{column: 0, line: 1}], message: "Variable `item': Defined more than once"}] == errors
    end
  end

  describe "list variables" do
    it "should work in a basic case" do
      doc = """
      query FindContacts($contacts:[String]) {contacts(contacts:$contacts)}
      """
      assert {:ok, %{variables: %Absinthe.Execution.Variables{
        processed: %{"contacts" => %Absinthe.Execution.Variable{value: value, type_stack: type}}
      }}} = doc |> parse(%{"contacts" => ["ben", "bob"]})
      assert value == ["ben", "bob"]
      assert type == ["String", Absinthe.Type.List]
    end

    it "it strips null values" do
      doc = """
      query FindContacts($contacts:[String]) {contacts(contacts:$contacts)}
      """
      assert {:ok, %{variables: %Absinthe.Execution.Variables{
        processed: %{"contacts" => %Absinthe.Execution.Variable{value: value, type_stack: _}}
      }}} = doc |> parse(%{"contacts" => ["ben", nil, nil, "bob", nil]})
      assert ["ben", "bob"] == value
    end

    it "returns an error if you give it a null value and it's non null" do
      doc = """
      query FindContacts($contacts:[String!]) {contacts(contacts:$contacts)}
      """
      assert {:error, %{errors: errors}} = doc |> parse(%{"contacts" => ["ben", nil, nil, "bob", nil]})
      assert errors != []
    end

    it "works when it's a list of input objects" do
      doc = """
      query FindContacts($contacts:[ContactInput]) {contacts(contacts:$contacts)}
      """
      assert {:ok, %{variables: %Absinthe.Execution.Variables{
        processed: %{"contacts" => %Absinthe.Execution.Variable{value: value, type_stack: type}}
      }}} = doc |> parse(__MODULE__.Schema, %{"contacts" => [%{"emailValue" => "ben"}, %{"emailValue" => "bob"}]})
      assert value == [%{email_value: "ben"}, %{email_value: "bob"}]
      assert type == ["ContactInput", Absinthe.Type.List]
    end
  end

  describe "input object variables" do
    it "should work in a basic case" do
      doc = """
      query FindContact($contact:ContactInput) {contact(contact:$contact)}
      """
      assert {:ok, %{errors: errors, variables: %Absinthe.Execution.Variables{
        raw: %{},
        processed: %{"contact" => %Absinthe.Execution.Variable{value: value, type_stack: type}}
      }}} = doc |> parse(__MODULE__.Schema, %{"contact" => %{"emailValue" => "ben"}})
      assert errors == []
      assert %{email_value: "ben"} == value
      assert ["ContactInput"] == type
    end

    it "should handle inner list fields" do
      doc = """
      query FindContact($contact:ContactInput) {contact(contact:$contact)}
      """
      assert {:ok, %{errors: errors, variables: %Absinthe.Execution.Variables{
        raw: %{},
        processed: %{"contact" => %Absinthe.Execution.Variable{value: value}}
      }}} = doc |> parse(__MODULE__.Schema, %{"contact" => %{"emailValue" => "ben", "addresses" => ["foo", "bar"]}})
      assert errors == []
      assert %{addresses: ["foo", "bar"], email_value: "ben"} == value
    end

    it "should handle inner input objects" do
      doc = """
      query FindContact($thing:NullableInput) {nullable(input:$thing)}
      """
      assert {:ok, %{errors: errors, variables: %Absinthe.Execution.Variables{
        raw: %{},
        processed: %{"thing" => %Absinthe.Execution.Variable{value: value}}
      }}} = doc |> parse(__MODULE__.Schema, %{"thing" => %{"contact" => %{"emailValue" => "ben"}}})
      assert errors == []
      assert %{contact: %{email_value: "ben"}} == value
    end

    it "should return an error if an inner scalar doesn't parse" do
      doc = """
      query FindContact($contact:ContactInput) {contact(contact:$contact)}
      """
      assert {:error, %{errors: errors}} = doc |> parse(__MODULE__.Schema, %{"contact" => %{"emailValue" => [1,2,3]}})
      assert [%{locations: [%{column: 0, line: 1}], message: "Variable `contact.emailValue' (String): Invalid value provided"}] == errors
    end

    it "should return an error when a required field is explicitly set to nil" do
      doc = """
      query FindContact($contact:ContactInput) {contact(contact:$contact)}
      """
      assert {:error, %{errors: errors}} = doc |> parse(__MODULE__.Schema, %{"contact" => %{"emailValue" => nil}})
      assert [%{locations: [%{column: 0, line: 1}], message: "Variable `contact.emailValue' (String): Not provided"}] == errors
    end

    it "tracks extra values" do
      doc = """
      query FindContact($contact:ContactInput) {user(contact:$contact)}
      """
      assert {:ok, %{errors: errors, data: data}} = doc |> Absinthe.run(__MODULE__.Schema, variables: %{"contact" => %{"emailValue" => "bob", "extra" => "thing"}})
      assert [%{locations: [%{column: 0, line: 1}], message: "Variable `contact.extra': Not present in schema"}] == errors
      assert %{"user" => "bob"} == data
    end

    it "returns an error for inner deprecated fields" do
      doc = """
      query FindContact($contact:ContactInput) {contact(contact:$contact)}
      """
      assert {:ok, %{errors: errors, variables: %Absinthe.Execution.Variables{
        processed: %{"contact" => %Absinthe.Execution.Variable{value: value}}}}} = doc |> parse(__MODULE__.Schema, %{"contact" => %{"emailValue" => "bob", "address" => "boo"}})
      assert %{email_value: "bob", address: "boo"} == value
      assert [%{locations: [%{column: 0, line: 1}], message: "Variable `contact.address' (String): Deprecated; no longer used"}] == errors
    end
  end

  describe "nested errors" do
    it "should return a useful error message for deeply nested errors" do
      doc = """
      query FindContact($contacts:[ContactInput]) {
        contacts(contacts:$contacts)
      }
      """
      assert {:ok, %{errors: errors}} = doc |> Absinthe.run(__MODULE__.Schema, variables: %{"contacts" => [%{"emailValue" => nil}]})
      assert [%{locations: [%{column: 0, line: 1}], message: "Variable `contacts[].emailValue' (String): Not provided"}] == errors
    end
  end

  describe "nil variables" do
    it "should be the same as not passing in a variable at all" do
      doc = """
      query FindContact($thing:String) {nullable(thing:$thing)}
      """
      assert {:ok, %{errors: errors, variables: %Absinthe.Execution.Variables{
        processed: processed}}} = doc |> parse(__MODULE__.Schema, %{"thing" => nil})
      assert [] == errors
      assert %{} == processed
      assert {:ok, %{data: data}} = doc |> Absinthe.run(__MODULE__.Schema, variables: %{"thing" => nil})
      assert %{"nullable" => "Got nothing"} == data
    end
  end

end
