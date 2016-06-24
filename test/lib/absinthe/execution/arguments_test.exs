defmodule Absinthe.Execution.ArgumentsTest do
  use Absinthe.Case, async: true

  import AssertResult

  defmodule Schema do
    use Absinthe.Schema

    @res %{
      true => "YES",
      false => "NO"
    }

    scalar :name do
      parse fn name -> {:ok, %{first_name: name}} end
      serialize fn %{first_name: name} -> name end
    end

    input_object :contact_input do
      field :email, non_null(:string)
      field :contact_type, :contact_type
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

      field :names, list_of(:name) do
        arg :names, list_of(:name)

        resolve fn %{names: names}, _ -> {:ok, names} end
      end

      field :numbers, list_of(:integer) do
        arg :numbers, list_of(:integer)

        resolve fn %{numbers: numbers}, _ -> {:ok, numbers} end
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
          name: [type: :name],
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
        arg :name, non_null(:name)
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
      assert_result {:ok, %{data: %{}, errors: [%{message: "Field `contacts': 1 required argument (`contacts') not provided"}, %{message: "Argument `contacts' (ContactInput): Not provided"}]}},
        doc |> Absinthe.run(Schema)
    end

    describe "list inputs" do
      it "works with basic scalars" do
        doc = """
        query GetNumbers($numbers:[Int!]!){numbers(numbers:$numbers)}
        """
        assert_result {:ok, %{data: %{"numbers" => [1, 2]}}}, doc |> Absinthe.run(Schema, variables: %{"numbers" =>[1, 2]})
      end

      it "works with custom scalars" do
        doc = """
        query GetNames($names:[Name!]!){names(names:$names)}
        """
        assert_result {:ok, %{data: %{"names" => ["Joe", "bob"]}}}, doc |> Absinthe.run(Schema, variables: %{"names" => ["Joe", "bob"]})
      end

      it "works with input objects" do
        doc = """
        query GetContacts($contacts:[ContactInput]){contacts(contacts:$contacts)}
        """
        assert_result {:ok, %{data: %{"contacts" => ["a@b.com", "c@d.com"]}}}, doc |> Absinthe.run(Schema, variables: %{"contacts" => [%{"email" => "a@b.com"}, %{"email" => "c@d.com"}]})
      end
    end

    describe "input object arguments" do
      it "works in a basic case" do
        doc = """
        query FindUser($contact: ContactInput!){
          user(contact:$contact)
        }
        """
        assert_result {:ok, %{data: %{"user" => "bubba@joe.com"}}}, doc |> Absinthe.run(Schema, variables: %{"contact" => %{"email" => "bubba@joe.com"}})
      end
    end

    describe "custom scalar arguments" do
      it "works when specified as non null" do
        doc = """
        { requiredThing(name: "bob") }
        """
        assert_result {:ok, %{data: %{"requiredThing" => "bob"}}}, doc |> Absinthe.run(Schema)
      end
      it "works when passed to resolution" do
        assert_result {:ok, %{data: %{"something" => "bob"}}}, "{ something(name: \"bob\") }" |> Absinthe.run(Schema)
      end
    end

    describe "boolean arguments" do

      it "are passed as arguments to resolution functions correctly" do
        doc = """
        query DoSomething($flag: Boolean!) {
          something(flag:$flag)
        }
        """
        assert_result {:ok, %{data: %{"something" => "YES"}}}, doc |> Absinthe.run(Schema, variables: %{"flag" => true})
        assert_result {:ok, %{data: %{"something" => "NO"}}}, doc |> Absinthe.run(Schema, variables: %{"flag" => false})
      end

    end

    describe "enum types" do
      it "should work with valid values" do
        doc = """
        query GetContact($type:ContactType){ contact(type: $type) }
        """
        assert_result {:ok, %{data: %{"contact" => "Email"}}}, doc |> Absinthe.run(Schema, variables: %{"type" => "Email"})
      end

      it "should work when nested" do
        doc = """
        query FindUser($contact: ContactInput!){
          user(contact:$contact)
        }
        """
        assert_result {:ok, %{data: %{"user" => "bubba@joe.com"}}}, doc |> Absinthe.run(Schema, variables: %{"contact" => %{"email" => "bubba@joe.com", "contactType" => "Email"}})
      end

      it "should return an error with invalid values" do
        assert_result {:ok, %{data: %{}, errors: [%{message: "Field `contact': 1 badly formed argument (`type') provided"}, %{message: "Argument `type' (ContactType): Invalid value provided"}]}},
          "{ contact(type: \"bagel\") }" |> Absinthe.run(Schema)
      end

      it "should return a deprecation notice if one of the values given is deprecated" do
        doc = """
        query GetContact($type:ContactType){ contact(type: $type) }
        """
        assert_result {:ok, %{data: %{"contact" => "SMS"}, errors: [%{message: "Variable `type.sms' (ContactType): Deprecated; Use phone instead"}]}}, doc |> Absinthe.run(Schema, variables: %{"type" => "SMS"})
      end
    end
  end

  describe "literal arguments" do
    describe "missing arguments" do
      it "returns the appropriate error" do
        doc = """
        { requiredThing }
        """
        assert_result {:ok, %{data: %{}, errors: [%{message: "Field `requiredThing': 1 required argument (`name') not provided"}, %{message: "Argument `name' (Name): Not provided"}]}}, doc |> Absinthe.run(Schema)
      end
    end

    describe "list inputs" do
      it "works with basic scalars" do
        doc = """
        {numbers(numbers: [1, 2])}
        """
        assert_result {:ok, %{data: %{"numbers" => [1, 2]}}}, doc |> Absinthe.run(Schema)
      end

      it "it will coerce a non list item if it's of the right type" do
        # per https://facebook.github.io/graphql/#sec-Lists
        doc = """
        {numbers(numbers: 1)}
        """
        assert_result {:ok, %{data: %{"numbers" => [1]}}}, doc |> Absinthe.run(Schema)
      end

      it "works with custom scalars" do
        doc = """
        {names(names: ["Joe", "bob"])}
        """
        assert_result {:ok, %{data: %{"names" => ["Joe", "bob"]}}}, doc |> Absinthe.run(Schema)
      end

      it "works with input objects" do
        doc = """
        {contacts(contacts: [{email: "a@b.com"}, {email: "c@d.com"}])}
        """
        assert_result {:ok, %{data: %{"contacts" => ["a@b.com", "c@d.com"]}}}, doc |> Absinthe.run(Schema)
      end

      it "returns deeply nested errors" do
        doc = """
        {contacts(contacts: [{email: "a@b.com"}, {foo: "c@d.com"}])}
        """
        assert_result {:ok, %{data: %{}, errors: [
          %{message: "Field `contacts': 1 required argument (`contacts[].email') not provided"},
          %{message: "Argument `contacts[].foo': Not present in schema"},
          %{message: "Argument `contacts[].email' (String): Not provided"},
        ]}},
          doc |> Absinthe.run(Schema)
      end
    end

    describe "input object arguments" do
      it "works in a basic case" do
        doc = """
        {user(contact: {email: "bubba@joe.com"})}
        """
        assert_result {:ok, %{data: %{"user" => "bubba@joe.com"}}}, doc |> Absinthe.run(Schema)
      end

      it "returns the correct error if an inner field is marked non null but is missing" do
        doc = """
        {user(contact: {foo: "buz"})}
        """
        assert_result {:ok, %{data: %{}, errors: [
          %{message: "Field `user': 1 required argument (`contact.email') not provided"},
          %{message: "Argument `contact.foo': Not present in schema"},
          %{message: "Argument `contact.email' (String): Not provided"},
        ]}},
          doc |> Absinthe.run(Schema)
      end

      it "returns an error if extra fields are given" do
        doc = """
        {user(contact: {email: "bubba", foo: "buz"})}
        """
        assert_result {:ok, %{data: %{"user" => "bubba"}, errors: [%{message: "Argument `contact.foo': Not present in schema"}]}},
          doc |> Absinthe.run(Schema)
      end
    end

    describe "custom scalar arguments" do
      it "works when specified as non null" do
        doc = """
        { requiredThing(name: "bob") }
        """
        assert_result {:ok, %{data: %{"requiredThing" => "bob"}}}, doc |> Absinthe.run(Schema)
      end
      it "works when passed to resolution" do
        assert_result {:ok, %{data: %{"something" => "bob"}}}, "{ something(name: \"bob\") }" |> Absinthe.run(Schema)
      end
    end

    describe "boolean arguments" do

      it "are passed as arguments to resolution functions correctly" do
        assert_result {:ok, %{data: %{"something" => "YES"}}}, "{ something(flag: true) }" |> Absinthe.run(Schema)
        assert_result {:ok, %{data: %{"something" => "NO"}}}, "{ something(flag: false) }" |> Absinthe.run(Schema)
        assert_result {:ok, %{data: %{"something" => "NO"}}}, "{ something }" |> Absinthe.run(Schema)
      end

      it "returns a correct error when passed the wrong type" do
        assert_result {:ok, %{data: %{}, errors: [%{message: "Field `something': 1 badly formed argument (`flag') provided"}, %{message: "Argument `flag' (Boolean): Invalid value provided"}]}},
          "{ something(flag: {foo: 1}) }" |> Absinthe.run(Schema)
      end
    end

    describe "enum types" do
      it "should work with valid values" do
        assert_result {:ok, %{data: %{"contact" => "Email"}}}, "{ contact(type: Email) }" |> Absinthe.run(Schema)
      end

      it "should return a deprecation notice if one of the values given is deprecated" do
        doc = """
        query GetContact { contact(type: SMS) }
        """
        assert_result {:ok, %{data: %{"contact" => "SMS"}, errors: [%{message: "Argument `type.sms' (ContactType): Deprecated; Use phone instead"}]}}, doc |> Absinthe.run(Schema)
      end

      it "should return an error with invalid values" do
        assert_result {:ok, %{data: %{}, errors: [%{message: "Field `contact': 1 badly formed argument (`type') provided"}, %{message: "Argument `type' (ContactType): Invalid value provided"}]}},
          "{ contact(type: \"bagel\") }" |> Absinthe.run(Schema)
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
      assert {:ok, %{errors: errors}} = doc |> Absinthe.run(Schema)
      assert [%{message: "Field `user': 1 badly formed argument (`contact.contactType') provided"}, %{message: "Argument `contact.contactType' (ContactType): Invalid value provided"}] = errors
    end
  end

end
