defmodule Absinthe.Execution.Arguments.InputObjectTest do
  use Absinthe.Case, async: true

  @schema Absinthe.Fixtures.ArgumentsSchema

  @graphql """
  query ($contact: ContactInput!) {
    user(contact: $contact)
  }
  """
  test "as variable, should work when nested" do
    assert_data(
      %{"user" => "bubba@joe.comasdf"},
      run(
        @graphql,
        @schema,
        variables: %{"contact" => %{"email" => "bubba@joe.com", "contactType" => "Email"}}
      )
    )
  end

  @graphql """
  query ($contact: ContactInput!) {
    user(contact: $contact)
  }
  """
  test "using variables, works in a basic case" do
    assert_data(
      %{"user" => "bubba@joe.comasdf"},
      run(@graphql, @schema, variables: %{"contact" => %{"email" => "bubba@joe.com"}})
    )
  end

  @graphql """
  query ($email: String) {
    contacts(contacts: [{email: $email}, {email: $email}])
  }
  """
  test "using inner variables" do
    assert_data(
      %{"contacts" => ["a@b.com", "a@b.com"]},
      run(@graphql, @schema, variables: %{"email" => "a@b.com"})
    )
  end

  @graphql """
  query ($input: InputStuff!) {
    stuff(stuff: $input)
  }
  """
  test "enforces non_null fields in input passed as variable" do
    assert_error_message_lines(
      [
        ~s(Argument "stuff" has invalid value $input.),
        ~s(In field "nonNullField": Expected type "String!", found null.)
      ],
      run(@graphql, @schema, variables: %{"input" => %{"value" => 5, "nonNullField" => nil}})
    )

    assert_error_message_lines(
      [
        ~s(Argument "stuff" has invalid value $input.),
        ~s(In field "nonNullField": Expected type "String!", found null.)
      ],
      run(@graphql, @schema, variables: %{"input" => %{"value" => 5}})
    )
  end

  @graphql """
  query ($email: String, $defaultWithString: String) {
    user(contact: {email: $email, defaultWithString: $defaultWithString})
  }
  """
  test "can set field default values" do
    assert_data(
      %{"user" => "bubba@joe.comasdf"},
      run(@graphql, @schema, variables: %{"email" => "bubba@joe.com"})
    )
  end

  @graphql """
  query ($email: String) {
    contacts(contacts: [{email: $email}, {email: $email}])
  }
  """
  test "with inner variables, when no variables are given, returns an error" do
    assert_error_message_lines(
      [
        ~s(Argument "contacts" has invalid value [{email: $email}, {email: $email}].),
        ~s(In element #1: Expected type "ContactInput", found {email: $email}.),
        ~s(In field "email": Expected type "String!", found $email.),
        ~s(In element #2: Expected type "ContactInput", found {email: $email}.),
        ~s(In field "email": Expected type "String!", found $email.)
      ],
      run(@graphql, @schema, variables: %{})
    )
  end

  @graphql """
  query {
    user(contact: {email: "bubba@joe.com"})
  }
  """
  test "using literals, works in a basic case" do
    assert_data(%{"user" => "bubba@joe.comasdf"}, run(@graphql, @schema))
  end

  @graphql """
  query {
    testBooleanInputObject(input: {flag: false})
  }
  """
  test "works with inner booleans set to false" do
    # This makes sure we don't accidentally filter out booleans when trying
    # to filter out nils
    assert_data(%{"testBooleanInputObject" => false}, run(@graphql, @schema))
  end

  @graphql """
  query {
    user(contact: {email: "bubba@joe.com", nestedContactInput: {email: "foo"}})
  }
  """
  test "works in a nested case" do
    assert_data(%{"user" => "bubba@joe.comasdf"}, run(@graphql, @schema))
  end

  @graphql """
  query {
    user(contact: {foo: "buz"})
  }
  """
  test "returns the correct error if an inner field is marked non null but is missing" do
    assert_error_message_lines(
      [
        ~s(Argument "contact" has invalid value {foo: "buz"}.),
        ~s(In field "email": Expected type "String!", found null.),
        ~s(In field "foo": Unknown field.)
      ],
      run(@graphql, @schema)
    )
  end

  @graphql """
  query {
    user(contact: {email: "bubba", foo: "buz"})
  }
  """
  test "returns an error if extra fields are given" do
    assert_error_message_lines(
      [
        ~s(Argument "contact" has invalid value {email: "bubba", foo: "buz"}.),
        ~s(In field "foo": Unknown field.)
      ],
      run(@graphql, @schema)
    )
  end

  test "input union" do
    assert_data(
      %{"eitherOr" => "THIS foo"},
      run(
        """
        query {
          eitherOr(
            unionArg: {this: "foo"}
          )
        }
        """,
        @schema
      )
    )

    assert_data(
      %{"eitherOr" => "THAT bar"},
      run(
        """
        query {
          eitherOr(
            objectArg: {value: "Ignore me"}
            unionArg: {__inputname: "ThatOne", that: "bar"}
          )
        }
        """,
        @schema
      )
    )
  end

  test "input union nested inside other input objects" do
    assert_data(
      %{"eitherOr" => "NESTED THIS foobar"},
      run(
        """
        query {
          eitherOr(
            nested: {
              nestedUnionArg: {
                __inputname: "ThisOne",
                this: "foobar"
              }
            }
          )
        }
        """,
        @schema
      )
    )
  end

  test "list of input unions" do
    assert_data(
      %{"eitherOr" => "ThisOne&THIS&ThatOne&THAT"},
      run(
        """
        query {
          eitherOr(
            listUnion: [{__inputname: "ThisOne", this: "THIS"}, {__inputname: "ThatOne", that: "THAT"}]
          )
        }
        """,
        @schema
      )
    )
  end
end
