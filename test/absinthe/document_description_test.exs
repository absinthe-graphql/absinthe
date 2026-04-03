defmodule Absinthe.DocumentDescriptionTest do
  @moduledoc """
  Tests for GraphQL document descriptions on executable definitions.

  This feature is part of the September 2025 GraphQL specification that allows
  descriptions (using triple-quoted strings) on operations (queries, mutations,
  subscriptions) and fragment definitions.

  See: https://spec.graphql.org/September2025/#sec-Descriptions
  """
  use Absinthe.Case, async: true

  alias Absinthe.{Blueprint, Language}

  describe "parsing queries with descriptions" do
    test "parses a query with a block string description" do
      query = """
      \"\"\"
      Fetches a user by their unique identifier.
      Used by the profile page and user settings.
      \"\"\"
      query GetUser($id: ID!) {
        user(id: $id) {
          id
          name
        }
      }
      """

      assert %Language.OperationDefinition{
               operation: :query,
               name: "GetUser",
               description: description
             } = parse_operation(query)

      assert description =~ "Fetches a user by their unique identifier"
      assert description =~ "Used by the profile page and user settings"
    end

    test "parses a query with a single-line string description" do
      query = """
      "Simple query to fetch the current user"
      query GetCurrentUser {
        currentUser {
          id
        }
      }
      """

      assert %Language.OperationDefinition{
               operation: :query,
               name: "GetCurrentUser",
               description: "Simple query to fetch the current user"
             } = parse_operation(query)
    end

    test "parses a query without description" do
      query = """
      query GetUser {
        user {
          id
        }
      }
      """

      assert %Language.OperationDefinition{
               operation: :query,
               name: "GetUser",
               description: nil
             } = parse_operation(query)
    end

    test "parses an anonymous query without description" do
      query = """
      query {
        user {
          id
        }
      }
      """

      assert %Language.OperationDefinition{
               operation: :query,
               name: nil,
               description: nil
             } = parse_operation(query)
    end

    test "parses a shorthand query without description" do
      query = """
      {
        user {
          id
        }
      }
      """

      assert %Language.OperationDefinition{
               operation: :query,
               shorthand: true,
               description: nil
             } = parse_operation(query)
    end
  end

  describe "parsing mutations with descriptions" do
    test "parses a mutation with a block string description" do
      query = """
      \"\"\"
      Creates a new user account.
      Requires admin privileges.
      \"\"\"
      mutation CreateUser($input: CreateUserInput!) {
        createUser(input: $input) {
          id
        }
      }
      """

      assert %Language.OperationDefinition{
               operation: :mutation,
               name: "CreateUser",
               description: description
             } = parse_operation(query)

      assert description =~ "Creates a new user account"
      assert description =~ "Requires admin privileges"
    end

    test "parses a mutation with a single-line description" do
      query = """
      "Updates user profile information"
      mutation UpdateProfile($input: UpdateProfileInput!) {
        updateProfile(input: $input) {
          success
        }
      }
      """

      assert %Language.OperationDefinition{
               operation: :mutation,
               name: "UpdateProfile",
               description: "Updates user profile information"
             } = parse_operation(query)
    end
  end

  describe "parsing subscriptions with descriptions" do
    test "parses a subscription with a block string description" do
      query = """
      \"\"\"
      Subscribes to real-time updates for a specific chat room.
      The subscription will automatically close after 24 hours.
      \"\"\"
      subscription OnNewMessage($roomId: ID!) {
        newMessage(roomId: $roomId) {
          id
          content
          sender {
            name
          }
        }
      }
      """

      assert %Language.OperationDefinition{
               operation: :subscription,
               name: "OnNewMessage",
               description: description
             } = parse_operation(query)

      assert description =~ "Subscribes to real-time updates"
      assert description =~ "automatically close after 24 hours"
    end

    test "parses a subscription with a single-line description" do
      query = """
      "Listen for user status changes"
      subscription OnUserStatusChange {
        userStatusChanged {
          userId
          status
        }
      }
      """

      assert %Language.OperationDefinition{
               operation: :subscription,
               name: "OnUserStatusChange",
               description: "Listen for user status changes"
             } = parse_operation(query)
    end
  end

  describe "parsing fragments with descriptions" do
    test "parses a fragment with a block string description" do
      query = """
      \"\"\"
      A fragment containing common user fields
      used across multiple queries.
      \"\"\"
      fragment UserFields on User {
        id
        name
        email
      }
      """

      assert %Language.Fragment{
               name: "UserFields",
               description: description
             } = parse_fragment(query)

      assert description =~ "A fragment containing common user fields"
      assert description =~ "used across multiple queries"
    end

    test "parses a fragment with a single-line description" do
      query = """
      "Basic address information"
      fragment AddressFields on Address {
        street
        city
        country
      }
      """

      assert %Language.Fragment{
               name: "AddressFields",
               description: "Basic address information"
             } = parse_fragment(query)
    end

    test "parses a fragment without description" do
      query = """
      fragment UserFields on User {
        id
        name
      }
      """

      assert %Language.Fragment{
               name: "UserFields",
               description: nil
             } = parse_fragment(query)
    end

    test "parses a fragment with directives and description" do
      query = """
      "User data fragment"
      fragment UserFields on User @deprecated(reason: "Use UserFieldsV2") {
        id
        name
      }
      """

      assert %Language.Fragment{
               name: "UserFields",
               description: "User data fragment",
               directives: [%Language.Directive{name: "deprecated"}]
             } = parse_fragment(query)
    end
  end

  describe "descriptions convert to Blueprint correctly" do
    test "operation description is preserved in Blueprint" do
      query = """
      "Get user by ID"
      query GetUser($id: ID!) {
        user(id: $id) {
          id
        }
      }
      """

      assert %Blueprint.Document.Operation{
               name: "GetUser",
               type: :query,
               description: "Get user by ID"
             } = blueprint_operation(query)
    end

    test "fragment description is preserved in Blueprint" do
      query = """
      "Common user fields"
      fragment UserFields on User {
        id
        name
      }
      """

      assert %Blueprint.Document.Fragment.Named{
               name: "UserFields",
               description: "Common user fields"
             } = blueprint_fragment(query)
    end

    test "operation without description has nil in Blueprint" do
      query = """
      query GetUser {
        user {
          id
        }
      }
      """

      assert %Blueprint.Document.Operation{
               name: "GetUser",
               description: nil
             } = blueprint_operation(query)
    end
  end

  describe "multiple definitions with descriptions" do
    test "parses document with multiple described operations" do
      query = """
      "Get all users"
      query GetUsers {
        users {
          id
        }
      }

      "Create a new user"
      mutation CreateUser {
        createUser {
          id
        }
      }
      """

      {:ok, %{input: doc}} = Absinthe.Phase.Parse.run(query)

      assert [
               %Language.OperationDefinition{
                 operation: :query,
                 name: "GetUsers",
                 description: "Get all users"
               },
               %Language.OperationDefinition{
                 operation: :mutation,
                 name: "CreateUser",
                 description: "Create a new user"
               }
             ] = doc.definitions
    end

    test "parses document with described operation and fragment" do
      query = """
      "Main query for user profile"
      query UserProfile($id: ID!) {
        user(id: $id) {
          ...UserFields
        }
      }

      "User fields used across the application"
      fragment UserFields on User {
        id
        name
        email
      }
      """

      {:ok, %{input: doc}} = Absinthe.Phase.Parse.run(query)

      assert [
               %Language.OperationDefinition{
                 operation: :query,
                 name: "UserProfile",
                 description: "Main query for user profile"
               },
               %Language.Fragment{
                 name: "UserFields",
                 description: "User fields used across the application"
               }
             ] = doc.definitions
    end

    test "parses document mixing described and non-described definitions" do
      query = """
      "This query has a description"
      query DescribedQuery {
        field1
      }

      query UndescribedQuery {
        field2
      }

      "This fragment has a description"
      fragment DescribedFragment on SomeType {
        field3
      }

      fragment UndescribedFragment on SomeType {
        field4
      }
      """

      {:ok, %{input: doc}} = Absinthe.Phase.Parse.run(query)

      assert [
               %Language.OperationDefinition{
                 name: "DescribedQuery",
                 description: "This query has a description"
               },
               %Language.OperationDefinition{
                 name: "UndescribedQuery",
                 description: nil
               },
               %Language.Fragment{
                 name: "DescribedFragment",
                 description: "This fragment has a description"
               },
               %Language.Fragment{
                 name: "UndescribedFragment",
                 description: nil
               }
             ] = doc.definitions
    end
  end

  describe "description edge cases" do
    test "handles multiline block string description" do
      query = """
      \"\"\"
      Line 1
      Line 2
      Line 3
      \"\"\"
      query MultilineQuery {
        field
      }
      """

      assert %Language.OperationDefinition{
               name: "MultilineQuery",
               description: description
             } = parse_operation(query)

      assert description =~ "Line 1"
      assert description =~ "Line 2"
      assert description =~ "Line 3"
    end

    test "handles empty description" do
      query = """
      ""
      query EmptyDescription {
        field
      }
      """

      assert %Language.OperationDefinition{
               name: "EmptyDescription",
               description: ""
             } = parse_operation(query)
    end

    test "handles description with newlines preserved" do
      query = """
      \"\"\"
      First paragraph.

      Second paragraph.
      \"\"\"
      query ParagraphQuery {
        field
      }
      """

      assert %Language.OperationDefinition{
               name: "ParagraphQuery",
               description: description
             } = parse_operation(query)

      assert description =~ "First paragraph"
      assert description =~ "Second paragraph"
    end
  end

  describe "SDL rendering with descriptions" do
    test "renders operation with description" do
      query = """
      "Fetches user data"
      query GetUser {
        user {
          id
        }
      }
      """

      {:ok, %{input: doc}} = Absinthe.Phase.Parse.run(query)
      rendered = inspect(doc, pretty: true)

      assert rendered =~ "Fetches user data"
      assert rendered =~ "query GetUser"
    end

    test "renders fragment with description" do
      query = """
      "User fields fragment"
      fragment UserFields on User {
        id
        name
      }
      """

      {:ok, %{input: doc}} = Absinthe.Phase.Parse.run(query)
      rendered = inspect(doc, pretty: true)

      assert rendered =~ "User fields fragment"
      assert rendered =~ "fragment UserFields on User"
    end

    test "renders operation without description" do
      query = """
      query GetUser {
        user {
          id
        }
      }
      """

      {:ok, %{input: doc}} = Absinthe.Phase.Parse.run(query)
      rendered = inspect(doc, pretty: true)

      # Should not have any description prefix
      refute rendered =~ ~r/^"""/m
      assert rendered =~ "query GetUser"
    end
  end

  describe "operations with variable definitions and descriptions" do
    test "query with description, variables, and directives" do
      query = """
      "Fetch user with optional fields"
      query GetUser($id: ID!, $includeEmail: Boolean = false) @cached(ttl: 60) {
        user(id: $id) {
          id
          name
        }
      }
      """

      assert %Language.OperationDefinition{
               operation: :query,
               name: "GetUser",
               description: "Fetch user with optional fields",
               variable_definitions: [_, _],
               directives: [%Language.Directive{name: "cached"}]
             } = parse_operation(query)
    end
  end

  # Helper functions

  defp parse_operation(text) do
    {:ok, %{input: doc}} = Absinthe.Phase.Parse.run(text)
    Enum.find(doc.definitions, &match?(%Language.OperationDefinition{}, &1))
  end

  defp parse_fragment(text) do
    {:ok, %{input: doc}} = Absinthe.Phase.Parse.run(text)
    Enum.find(doc.definitions, &match?(%Language.Fragment{}, &1))
  end

  defp blueprint_operation(text) do
    {:ok, %{input: doc}} = Absinthe.Phase.Parse.run(text)

    doc.definitions
    |> Enum.find(&match?(%Language.OperationDefinition{}, &1))
    |> Blueprint.Draft.convert(doc)
  end

  defp blueprint_fragment(text) do
    {:ok, %{input: doc}} = Absinthe.Phase.Parse.run(text)

    doc.definitions
    |> Enum.find(&match?(%Language.Fragment{}, &1))
    |> Blueprint.Draft.convert(doc)
  end
end
