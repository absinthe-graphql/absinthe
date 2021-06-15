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

  describe "open ended scalar" do
    @graphql """
    query {
      entities(representations: [{__typename: "Product", id: "123"}])
    }
    """
    test "supports passing an object directly" do
      assert_data(
        %{"entities" => [%{"__typename" => "Product", "id" => "123"}]},
        run(@graphql, @schema)
      )
    end

    @graphql """
    query($representations: [Any!]!) {
      entities(representations: $representations)
    }
    """
    test "supports passing an object through variables" do
      assert_data(
        %{"entities" => [%{"__typename" => "Product", "id" => "123"}]},
        run(@graphql, @schema,
          variables: %{"representations" => [%{"__typename" => "Product", "id" => "123"}]}
        )
      )
    end

    @graphql """
    query {
      entities(representations: [{__typename: "Product", id: null}])
    }
    """
    test "supports passing an object with a nested value of null" do
      assert_data(
        %{"entities" => [%{"__typename" => "Product", "id" => nil}]},
        run(@graphql, @schema)
      )
    end

    @graphql """
    query {
      entities(representations: [{__typename: "Product", contact_type: PHONE}])
    }
    """
    test "supports passing an object with a nested value of ENUM" do
      assert_data(
        %{"entities" => [%{"__typename" => "Product", "contact_type" => "PHONE"}]},
        run(@graphql, @schema)
      )
    end
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
