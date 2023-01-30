defmodule Absinthe.Execution.Arguments.ListTest do
  use Absinthe.Case, async: true

  @schema Absinthe.Fixtures.ArgumentsSchema

  @graphql """
  query ($contacts: [ContactInput]) {
    contacts(contacts: $contacts)
  }
  """
  test "when missing for a non-null argument, should raise an error" do
    msg = ~s(In argument "contacts": Expected type "[ContactInput]!", found null.)
    assert_error_message(msg, run(@graphql, @schema))
  end

  @graphql """
  query ($numbers: [Int!]!) {
    numbers(numbers: $numbers)
  }
  """
  test "using variables, works with basic scalars" do
    assert_data(%{"numbers" => [1, 2]}, run(@graphql, @schema, variables: %{"numbers" => [1, 2]}))
  end

  @graphql """
  query ($names: [InputName!]!) {
    names(names: $names)
  }
  """
  test "works with custom scalars" do
    assert_data(
      %{"names" => ["Joe", "bob"]},
      run(@graphql, @schema, variables: %{"names" => ["Joe", "bob"]})
    )
  end

  @graphql """
  query ($contacts: [ContactInput]!) {
    contacts(contacts: $contacts)
  }
  """
  test "using variables, works with input objects" do
    assert_data(
      %{"contacts" => ["a@b.com", "c@d.com"]},
      run(
        @graphql,
        @schema,
        variables: %{
          "contacts" => [
            %{"email" => "a@b.com"},
            %{"email" => "c@d.com"}
          ]
        }
      )
    )
  end

  @graphql """
  query ($contact: ContactInput) {
    contacts(contacts: [$contact, $contact])
  }
  """
  test "with inner variables" do
    assert_data(
      %{"contacts" => ["a@b.com", "a@b.com"]},
      run(@graphql, @schema, variables: %{"contact" => %{"email" => "a@b.com"}})
    )
  end

  @graphql """
  query ($contact: ContactInput) {
    contacts(contacts: [$contact, $contact])
  }
  """
  test "with inner variables when no variables are given" do
    assert_data(%{"contacts" => []}, run(@graphql, @schema, variables: %{}))
  end

  @graphql """
  query {
    names(names: ["Joe", "bob"])
  }
  """
  test "custom scalars literals can be included" do
    assert_data(%{"names" => ["Joe", "bob"]}, run(@graphql, @schema))
  end

  @graphql """
  query {
    numbers(numbers: [1, 2])
  }
  """
  test "using literals, works with basic scalars" do
    assert_data(%{"numbers" => [1, 2]}, run(@graphql, @schema))
  end

  @graphql """
  query {
    listOfLists(items: [["foo"], ["bar", "baz"]])
  }
  """
  test "works with nested lists" do
    assert_data(%{"listOfLists" => [["foo"], ["bar", "baz"]]}, run(@graphql, @schema))
  end

  @graphql """
  query {
    numbers(numbers: 1)
  }
  """
  test "it will coerce a non list item if it's of the right type" do
    # per https://facebook.github.io/graphql/#sec-Lists
    assert_data(%{"numbers" => [1]}, run(@graphql, @schema))
  end

  @graphql """
  query {
    contacts(contacts: [{email: "a@b.com"}, {email: "c@d.com"}])
  }
  """
  test "using literals, works with input objects" do
    assert_data(%{"contacts" => ["a@b.com", "c@d.com"]}, run(@graphql, @schema))
  end

  @graphql """
  query {
    contacts(contacts: [{email: "a@b.com"}, {foo: "c@d.com"}])
  }
  """
  test "returns deeply nested errors" do
    assert_error_message_lines(
      [
        ~s(Argument "contacts" has invalid value [{email: "a@b.com"}, {foo: "c@d.com"}].),
        ~s(In element #2: Expected type "ContactInput", found {foo: "c@d.com"}.),
        ~s(In field "email": Expected type "String!", found null.),
        ~s(In field "foo": Unknown field.)
      ],
      run(@graphql, @schema)
    )
  end
end
