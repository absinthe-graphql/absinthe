defmodule Absinthe.Type.SemanticNullabilityTest do
  use Absinthe.Case, async: true

  alias Absinthe.Type.SemanticNullability

  defmodule TestSchema do
    use Absinthe.Schema

    import_types Absinthe.Type.BuiltIns.SemanticNonNull

    object :post do
      field :id, :id
      field :title, :string
    end

    object :user do
      @desc "User's email - semantically non-null"
      field :email, :string do
        directive :semantic_non_null
      end

      @desc "User's name - no semantic non-null"
      field :name, :string

      @desc "User's posts - list with semantic non-null on items"
      field :posts, list_of(:post) do
        directive :semantic_non_null, levels: [1]
      end

      @desc "User's friends - semantic non-null at both levels"
      field :friends, list_of(:user) do
        directive :semantic_non_null, levels: [0, 1]
      end

      @desc "User's bio - using shorthand notation"
      field :bio, :string, semantic_non_null: true

      @desc "User's tags - using shorthand with levels"
      field :tags, list_of(:string), semantic_non_null: [0, 1]
    end

    query do
      field :user, :user do
        resolve fn _, _ -> {:ok, %{email: "test@example.com", name: "Test"}} end
      end

      field :users, list_of(:user), semantic_non_null: [0] do
        resolve fn _, _ -> {:ok, []} end
      end
    end
  end

  describe "@semanticNonNull directive" do
    test "directive is available in schema" do
      directives = Absinthe.Schema.directives(TestSchema)
      directive_identifiers = Enum.map(directives, & &1.identifier)

      assert :semantic_non_null in directive_identifiers
    end

    test "directive has correct description" do
      directive =
        Absinthe.Schema.directives(TestSchema)
        |> Enum.find(&(&1.identifier == :semantic_non_null))

      assert directive.description =~ "semantically non-null"
    end

    test "directive has levels argument with default value" do
      directive =
        Absinthe.Schema.directives(TestSchema)
        |> Enum.find(&(&1.identifier == :semantic_non_null))

      levels_arg = Map.get(directive.args, :levels)
      assert levels_arg != nil
      assert levels_arg.default_value == [0]
    end

    test "directive applies to field_definition" do
      directive =
        Absinthe.Schema.directives(TestSchema)
        |> Enum.find(&(&1.identifier == :semantic_non_null))

      assert :field_definition in directive.locations
    end
  end

  describe "SemanticNullability.semantic_non_null?/1" do
    test "returns true for field with @semanticNonNull directive" do
      user_type = Absinthe.Schema.lookup_type(TestSchema, :user)
      email_field = user_type.fields[:email]

      assert SemanticNullability.semantic_non_null?(email_field) == true
    end

    test "returns false for field without @semanticNonNull directive" do
      user_type = Absinthe.Schema.lookup_type(TestSchema, :user)
      name_field = user_type.fields[:name]

      assert SemanticNullability.semantic_non_null?(name_field) == false
    end

    test "returns true for field with shorthand notation" do
      user_type = Absinthe.Schema.lookup_type(TestSchema, :user)
      bio_field = user_type.fields[:bio]

      assert SemanticNullability.semantic_non_null?(bio_field) == true
    end

    test "returns true for field with shorthand levels notation" do
      user_type = Absinthe.Schema.lookup_type(TestSchema, :user)
      tags_field = user_type.fields[:tags]

      assert SemanticNullability.semantic_non_null?(tags_field) == true
    end
  end

  describe "SemanticNullability.levels/1" do
    test "returns default levels [0] for basic @semanticNonNull" do
      user_type = Absinthe.Schema.lookup_type(TestSchema, :user)
      email_field = user_type.fields[:email]

      assert SemanticNullability.levels(email_field) == [0]
    end

    test "returns nil for field without @semanticNonNull" do
      user_type = Absinthe.Schema.lookup_type(TestSchema, :user)
      name_field = user_type.fields[:name]

      assert SemanticNullability.levels(name_field) == nil
    end

    test "returns custom levels [1] for list items only" do
      user_type = Absinthe.Schema.lookup_type(TestSchema, :user)
      posts_field = user_type.fields[:posts]

      assert SemanticNullability.levels(posts_field) == [1]
    end

    test "returns multiple levels [0, 1] for both field and items" do
      user_type = Absinthe.Schema.lookup_type(TestSchema, :user)
      friends_field = user_type.fields[:friends]

      assert SemanticNullability.levels(friends_field) == [0, 1]
    end

    test "returns levels from shorthand notation" do
      user_type = Absinthe.Schema.lookup_type(TestSchema, :user)
      bio_field = user_type.fields[:bio]

      assert SemanticNullability.levels(bio_field) == [0]
    end

    test "returns custom levels from shorthand notation" do
      user_type = Absinthe.Schema.lookup_type(TestSchema, :user)
      tags_field = user_type.fields[:tags]

      assert SemanticNullability.levels(tags_field) == [0, 1]
    end
  end

  describe "SemanticNullability.level_non_null?/2" do
    test "returns true when level is in the list" do
      user_type = Absinthe.Schema.lookup_type(TestSchema, :user)
      friends_field = user_type.fields[:friends]

      assert SemanticNullability.level_non_null?(friends_field, 0) == true
      assert SemanticNullability.level_non_null?(friends_field, 1) == true
    end

    test "returns false when level is not in the list" do
      user_type = Absinthe.Schema.lookup_type(TestSchema, :user)
      email_field = user_type.fields[:email]

      assert SemanticNullability.level_non_null?(email_field, 0) == true
      assert SemanticNullability.level_non_null?(email_field, 1) == false
    end

    test "returns false for field without semantic non-null" do
      user_type = Absinthe.Schema.lookup_type(TestSchema, :user)
      name_field = user_type.fields[:name]

      assert SemanticNullability.level_non_null?(name_field, 0) == false
    end
  end

  describe "SemanticNullability.validate_levels/2" do
    test "validates level 0 for any type" do
      assert SemanticNullability.validate_levels([0], :string) == :ok
    end

    test "validates level 1 for list type" do
      list_type = %Absinthe.Type.List{of_type: :string}
      assert SemanticNullability.validate_levels([1], list_type) == :ok
    end

    test "validates levels [0, 1] for list type" do
      list_type = %Absinthe.Type.List{of_type: :string}
      assert SemanticNullability.validate_levels([0, 1], list_type) == :ok
    end

    test "returns error for level 1 on non-list type" do
      assert {:error, message} = SemanticNullability.validate_levels([1], :string)
      assert message =~ "level 1 requires 1 nested list"
    end

    test "validates level 2 for nested list type" do
      nested_list = %Absinthe.Type.List{of_type: %Absinthe.Type.List{of_type: :string}}
      assert SemanticNullability.validate_levels([2], nested_list) == :ok
    end

    test "handles non_null wrapper" do
      non_null_list = %Absinthe.Type.NonNull{of_type: %Absinthe.Type.List{of_type: :string}}
      assert SemanticNullability.validate_levels([1], non_null_list) == :ok
    end

    test "returns error for negative levels" do
      assert {:error, message} = SemanticNullability.validate_levels([-1], :string)
      assert message =~ "non-negative"
    end
  end

  describe "introspection" do
    test "isSemanticNonNull returns true for annotated fields" do
      result =
        """
        {
          __type(name: "User") {
            fields {
              name
              isSemanticNonNull
            }
          }
        }
        """
        |> Absinthe.run(TestSchema)

      assert {:ok, %{data: %{"__type" => %{"fields" => fields}}}} = result

      email_field = Enum.find(fields, &(&1["name"] == "email"))
      assert email_field["isSemanticNonNull"] == true

      name_field = Enum.find(fields, &(&1["name"] == "name"))
      assert name_field["isSemanticNonNull"] == false
    end

    test "semanticNonNullLevels returns the levels array" do
      result =
        """
        {
          __type(name: "User") {
            fields {
              name
              semanticNonNullLevels
            }
          }
        }
        """
        |> Absinthe.run(TestSchema)

      assert {:ok, %{data: %{"__type" => %{"fields" => fields}}}} = result

      email_field = Enum.find(fields, &(&1["name"] == "email"))
      assert email_field["semanticNonNullLevels"] == [0]

      name_field = Enum.find(fields, &(&1["name"] == "name"))
      assert name_field["semanticNonNullLevels"] == nil

      friends_field = Enum.find(fields, &(&1["name"] == "friends"))
      assert friends_field["semanticNonNullLevels"] == [0, 1]

      posts_field = Enum.find(fields, &(&1["name"] == "posts"))
      assert posts_field["semanticNonNullLevels"] == [1]
    end

    test "full introspection query returns semantic nullability info" do
      result =
        """
        {
          __type(name: "User") {
            fields {
              name
              isSemanticNonNull
              semanticNonNullLevels
              type {
                kind
                name
              }
            }
          }
        }
        """
        |> Absinthe.run(TestSchema)

      assert {:ok, %{data: %{"__type" => %{"fields" => fields}}}} = result

      # Check that all expected fields are present
      field_names = Enum.map(fields, & &1["name"])
      assert "email" in field_names
      assert "name" in field_names
      assert "posts" in field_names
      assert "friends" in field_names
      assert "bio" in field_names
      assert "tags" in field_names
    end
  end

  describe "schema notation shorthand" do
    defmodule ShorthandSchema do
      use Absinthe.Schema

      query do
        field :simple, :string, semantic_non_null: true
        field :with_levels, list_of(:string), semantic_non_null: [0, 1]

        field :normal, :string
      end
    end

    test "semantic_non_null: true applies default levels" do
      query_type = Absinthe.Schema.lookup_type(ShorthandSchema, :query)
      simple_field = query_type.fields[:simple]

      assert SemanticNullability.semantic_non_null?(simple_field) == true
      assert SemanticNullability.levels(simple_field) == [0]
    end

    test "semantic_non_null: [levels] applies custom levels" do
      query_type = Absinthe.Schema.lookup_type(ShorthandSchema, :query)
      with_levels_field = query_type.fields[:with_levels]

      assert SemanticNullability.semantic_non_null?(with_levels_field) == true
      assert SemanticNullability.levels(with_levels_field) == [0, 1]
    end

    test "fields without semantic_non_null are not affected" do
      query_type = Absinthe.Schema.lookup_type(ShorthandSchema, :query)
      normal_field = query_type.fields[:normal]

      assert SemanticNullability.semantic_non_null?(normal_field) == false
      assert SemanticNullability.levels(normal_field) == nil
    end
  end

  describe "directive in schema listing" do
    test "semanticNonNull appears in __schema directives" do
      result =
        """
        {
          __schema {
            directives {
              name
              locations
              args {
                name
                type {
                  kind
                  name
                  ofType {
                    kind
                    name
                    ofType {
                      kind
                      name
                      ofType {
                        kind
                        name
                      }
                    }
                  }
                }
                defaultValue
              }
            }
          }
        }
        """
        |> Absinthe.run(TestSchema)

      assert {:ok, %{data: %{"__schema" => %{"directives" => directives}}}} = result

      semantic_non_null = Enum.find(directives, &(&1["name"] == "semanticNonNull"))
      assert semantic_non_null != nil
      assert "FIELD_DEFINITION" in semantic_non_null["locations"]

      # Check the levels argument
      levels_arg = Enum.find(semantic_non_null["args"], &(&1["name"] == "levels"))
      assert levels_arg != nil
      assert levels_arg["defaultValue"] == "[0]"

      # Check the type is non_null(list_of(non_null(:integer)))
      assert levels_arg["type"]["kind"] == "NON_NULL"
      assert levels_arg["type"]["ofType"]["kind"] == "LIST"
      assert levels_arg["type"]["ofType"]["ofType"]["kind"] == "NON_NULL"
      assert levels_arg["type"]["ofType"]["ofType"]["ofType"]["name"] == "Int"
    end
  end
end
