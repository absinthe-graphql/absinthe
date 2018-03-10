defmodule Absinthe.Execution.ArgumentsTest do
  use Absinthe.Case, async: true

  @schema Absinthe.Fixtures.ArgumentsSchema

  @graphql """
  query {
    contact
  }
  """
  test "when nullable, if omitted should still be passed as an argument map to the resolver" do
    assert_data(%{"contact" => nil}, run(@graphql, @schema))
  end

  @graphql """
  query {
    requiredThing
  }
  """
  test "when non-nullable and missing, returns an appropriate error" do
    assert_error_message(
      ~s(In argument "name": Expected type "InputName!", found null.),
      run(@graphql, @schema)
    )
  end

  describe "errors" do
    @graphql """
    query FindUser {
    user(contact: {email: "bubba@joe.com", contactType: 1})
    }
    """
    test "should adapt internal field names on error" do
      assert_error_message_lines(
        [
          ~s(Argument "contact" has invalid value {email: "bubba@joe.com", contactType: 1}.),
          ~s(In field "contactType": Expected type "ContactType", found 1.)
        ],
        run(@graphql, @schema)
      )
    end
  end
end
