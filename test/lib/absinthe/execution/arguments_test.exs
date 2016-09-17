defmodule Absinthe.Execution.ArgumentsTest do
  use Absinthe.Case, async: true

  import AssertResult

  defmodule Schema do
    use Absinthe.Schema

    @res %{
      true => "YES",
      false => "NO"
    }

    scalar :input_name do
      parse fn %{value: value} -> {:ok, %{first_name: value}} end
      serialize fn %{first_name: name} -> name end
    end

    scalar :name do
      serialize &to_string/1
      parse fn
        %Absinthe.Blueprint.Input.String{} = string ->
          string.value
        _ ->
          :error
      end
    end

    input_object :contact_input do
      field :email, non_null(:string)
      field :contact_type, :contact_type
      field :nested_contact_input, :nested_contact_input
    end

    input_object :nested_contact_input do
      field :email, non_null(:string)
    end

    enum :contact_type do
      value :email, name: "Email", as: "Email"
      value :phone
      value :sms, deprecate: "Use phone instead"
    end

    query do

      field :contact, :contact_type do
        arg :type, :contact_type

        resolve fn %{type: val}, _ -> {:ok, val} end
      end

      field :contacts, list_of(:string) do
        arg :contacts, non_null(list_of(:contact_input))

        resolve fn %{contacts: contacts}, _ ->
          {:ok, Enum.map(contacts, &Map.get(&1, :email))}
        end
      end

      field :names, list_of(:input_name) do
        arg :names, list_of(:input_name)

        resolve fn %{names: names}, _ -> {:ok, names} end
      end

      field :numbers, list_of(:integer) do
        arg :numbers, list_of(:integer)

        resolve fn
          %{numbers: numbers}, _ ->
            {:ok, numbers}
          end
      end

      field :user, :string do
        arg :contact, :contact_input
        resolve fn
          %{contact: %{email: email}}, _ ->
            {:ok, email}
          args, _ ->
            {:error, "Got #{inspect args} instead"}
        end
      end

      field :something,
        type: :string,
        args: [
          name: [type: :input_name],
          flag: [type: :boolean, default_value: false],
        ],
        resolve: fn
          %{name: %{first_name: name}}, _ ->
            {:ok, name}
          %{flag: val}, _ ->
            {:ok, @res[val]}
          _, _ ->
            {:error, "No value provided for flag argument"}
        end
      field :required_thing, :string do
        arg :name, non_null(:input_name)
        resolve fn
          %{name: %{first_name: name}}, _ -> {:ok, name}
          args, _ -> {:error, "Got #{inspect args} instead"}
        end
      end

    end

  end

  describe "arguments with variables" do
    it "should raise an error when a non null argument variable is null" do
      doc = """
      query GetContacts($contacts:[ContactInput]){contacts(contacts:$contacts)}
      """
      assert_result {:ok, %{errors: [%{message: ~s(In argument "contacts": Expected type "[ContactInput]!", found null.)}]}},
        doc |> run(Schema)
    end

    describe "list inputs" do

      it "works with basic scalars" do
        doc = """
        query GetNumbers($numbers:[Int!]!){numbers(numbers:$numbers)}
        """
        assert_result {:ok, %{data: %{"numbers" => [1, 2]}}}, doc |> run(Schema, variables: %{"numbers" =>[1, 2]})
      end

      it "works with custom scalars" do
        doc = """
        query GetNames($names:[Name!]!){names(names:$names)}
        """
        assert_result {:ok, %{data: %{"names" => ["Joe", "bob"]}}}, doc |> run(Schema, variables: %{"names" => ["Joe", "bob"]})
      end

      it "works with input objects" do
        doc = """
        query GetContacts($contacts:[ContactInput]){contacts(contacts:$contacts)}
        """
        assert_result {:ok, %{data: %{"contacts" => ["a@b.com", "c@d.com"]}}}, doc |> run(Schema, variables: %{"contacts" => [%{"email" => "a@b.com"}, %{"email" => "c@d.com"}]})
      end
    end

    describe "input object arguments" do
      it "works in a basic case" do
        doc = """
        query FindUser($contact: ContactInput!){
          user(contact:$contact)
        }
        """
        assert_result {:ok, %{data: %{"user" => "bubba@joe.com"}}}, doc |> run(Schema, variables: %{"contact" => %{"email" => "bubba@joe.com"}})
      end
    end

    describe "custom scalar arguments" do
      it "works when specified as non null" do
        doc = """
        { requiredThing(name: "bob") }
        """
        assert_result {:ok, %{data: %{"requiredThing" => "bob"}}}, doc |> run(Schema)
      end

      it "works when passed to resolution" do
        assert_result {:ok, %{data: %{"something" => "bob"}}}, "{ something(name: \"bob\") }" |> run(Schema)
      end
    end

    describe "boolean arguments" do

      it "are passed as arguments to resolution functions correctly" do
        doc = """
        query DoSomething($flag: Boolean!) {
          something(flag:$flag)
        }
        """
        assert_result {:ok, %{data: %{"something" => "YES"}}}, doc |> run(Schema, variables: %{"flag" => true})
        assert_result {:ok, %{data: %{"something" => "NO"}}}, doc |> run(Schema, variables: %{"flag" => false})
      end

      it "If a variable is not provided schema default value is used" do
        doc = """
        query DoSomething($flag: Boolean!) {
          something(flag: $flag)
        }
        """
        assert_result {:ok, %{data: %{"something" => "NO"}}}, doc |> Absinthe.run(Schema, variables: %{})
      end

      it "works with input objects with inner variables" do
        doc = """
        query Blah($email: String){contacts(contacts: [{email: $email}, {email: $email}])}
        """
        assert_result {:ok, %{data: %{"contacts" => ["a@b.com", "c@d.com"]}}}, doc |> run(Schema, variables: %{"email" => "a@b.com"})
      end

      it "works with input objects with inner variables when no variables are given" do
        doc = """
        query Blah($email: String){contacts(contacts: [{email: $email}, {email: $email}])}
        """
        assert_result {:ok, %{data: %{"contacts" => ["a@b.com", "c@d.com"]}}}, doc |> run(Schema, variables: %{})
      end

      it "works with lists with inner variables" do
        doc = """
        query Blah($contact: ContactInput){contacts(contacts: [$contact, $contact])}
        """
        assert_result {:ok, %{data: %{"contacts" => ["a@b.com", "c@d.com"]}}}, doc |> run(Schema, variables: %{"contact" => %{"email" => "a@b.com"}})
      end

      it "works with lists with inner variables when no variables are given" do
        doc = """
        query Blah($contact: ContactInput){contacts(contacts: [$contact, $contact])}
        """
        assert_result {:ok, %{data: %{"contacts" => []}}}, doc |> run(Schema, variables: %{})
      end

    end

    describe "enum types" do
      it "should work with valid values" do
        doc = """
        query GetContact($type:ContactType){ contact(type: $type) }
        """
        assert_result {:ok, %{data: %{"contact" => "Email"}}}, doc |> run(Schema, variables: %{"type" => "Email"})
      end

      it "should work when nested" do
        doc = """
        query FindUser($contact: ContactInput!){
          user(contact:$contact)
        }
        """
        assert_result {:ok, %{data: %{"user" => "bubba@joe.com"}}}, doc |> run(Schema, variables: %{"contact" => %{"email" => "bubba@joe.com", "contactType" => "Email"}})
      end

      it "should return an error with invalid values" do
        assert_result {:ok, %{errors: [%{message: ~s(Argument "type" has invalid value "bagel".)}]}},
          "{ contact(type: \"bagel\") }" |> run(Schema)
      end

    end
  end

  describe "literal arguments" do
    describe "missing arguments" do

      it "returns the appropriate error" do
        doc = """
        { requiredThing }
        """
        assert_result {:ok, %{errors: [%{message: ~s(In argument "name": Expected type "InputName!", found null.)}]}}, doc |> run(Schema)
      end
    end

    describe "list inputs" do
      it "works with basic scalars" do
        doc = """
        {numbers(numbers: [1, 2])}
        """
        assert_result {:ok, %{data: %{"numbers" => [1, 2]}}}, doc |> run(Schema)
      end

      it "it will coerce a non list item if it's of the right type" do
        # per https://facebook.github.io/graphql/#sec-Lists
        doc = """
        {numbers(numbers: 1)}
        """
        assert_result {:ok, %{data: %{"numbers" => [1]}}}, doc |> run(Schema)
      end

      it "works with custom scalars" do
        doc = """
        {names(names: ["Joe", "bob"])}
        """
        assert_result {:ok, %{data: %{"names" => ["Joe", "bob"]}}}, doc |> run(Schema)
      end

      it "works with input objects" do
        doc = """
        {contacts(contacts: [{email: "a@b.com"}, {email: "c@d.com"}])}
        """
        assert_result {:ok, %{data: %{"contacts" => ["a@b.com", "c@d.com"]}}}, doc |> run(Schema)
      end

      it "returns deeply nested errors" do
        doc = """
        {contacts(contacts: [{email: "a@b.com"}, {foo: "c@d.com"}])}
        """
        assert_result {:ok, %{errors: [
          %{message: ~s(Argument "contacts" has invalid value [{email: "a@b.com"}, {foo: "c@d.com"}].\nIn element #2: Expected type "ContactInput", found {foo: "c@d.com", email: null}.\nIn field "foo": Unknown field.\nIn field "email": Expected type "String!", found null.)},
        ]}},
          doc |> run(Schema)
      end
    end

    describe "input object arguments" do
      it "works in a basic case" do
        doc = """
        {user(contact: {email: "bubba@joe.com"})}
        """
        assert_result {:ok, %{data: %{"user" => "bubba@joe.com"}}}, doc |> run(Schema)
      end

      it "works in a nested case" do
        doc = """
        {user(contact: {email: "bubba@joe.com", nestedContactInput: {email: "foo"}})}
        """
        assert_result {:ok, %{data: %{"user" => "bubba@joe.com"}}}, doc |> run(Schema)
      end

      it "returns the correct error if an inner field is marked non null but is missing" do
        doc = """
        {user(contact: {foo: "buz"})}
        """
        assert_result {:ok, %{errors: [
          %{message: ~s(Argument "contact" has invalid value {foo: "buz"}.\nIn field "foo": Unknown field.\nIn field "email": Expected type "String!", found null.)},
        ]}},
          doc |> run(Schema)
      end

      it "returns an error if extra fields are given" do
        doc = """
        {user(contact: {email: "bubba", foo: "buz"})}
        """
        assert_result {:ok, %{errors: [%{message: "Argument \"contact\" has invalid value {email: \"bubba\", foo: \"buz\"}.\nIn field \"foo\": Unknown field."}]}},
          doc |> run(Schema)
      end
    end

    describe "custom scalar arguments" do
      it "works when specified as non null" do
        doc = """
        { requiredThing(name: "bob") }
        """
        assert_result {:ok, %{data: %{"requiredThing" => "bob"}}}, doc |> run(Schema)
      end
      it "works when passed to resolution" do
        assert_result {:ok, %{data: %{"something" => "bob"}}}, "{ something(name: \"bob\") }" |> run(Schema)
      end
    end

    describe "boolean arguments" do

      it "are passed as arguments to resolution functions correctly" do
        assert_result {:ok, %{data: %{"something" => "YES"}}}, "{ something(flag: true) }" |> run(Schema)
        assert_result {:ok, %{data: %{"something" => "NO"}}}, "{ something(flag: false) }" |> run(Schema)
        assert_result {:ok, %{data: %{"something" => "NO"}}}, "{ something }" |> run(Schema)
      end

      it "returns a correct error when passed the wrong type" do
        assert_result {:ok, %{errors: [%{message: ~s(Argument "flag" has invalid value {foo: 1}.)}]}},
          "{ something(flag: {foo: 1}) }" |> run(Schema)
      end
    end

    describe "enum types" do
      it "should work with valid values" do
        assert_result {:ok, %{data: %{"contact" => "Email"}}}, "{ contact(type: Email) }" |> run(Schema)
      end
      it "should return an error with invalid values" do
        assert_result {:ok, %{errors: [%{message: ~s(Argument "type" has invalid value "bagel".)}]}},
          "{ contact(type: \"bagel\") }" |> run(Schema)
      end
    end
  end

  describe "camelized errors" do
    it "should adapt internal field names on error" do
      doc = """
      query FindUser {
        user(contact: {email: "bubba@joe.com", contactType: 1})
      }
      """
      assert_result {:ok, %{errors: [%{message: ~s(Argument "contact" has invalid value {email: "bubba@joe.com", contactType: 1}.\nIn field "contactType": Expected type "ContactType", found 1.)}]}}, run(doc, Schema)
    end
  end

end
