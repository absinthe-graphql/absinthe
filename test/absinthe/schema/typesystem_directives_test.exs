defmodule Absinthe.Schema.TypesystemDirectivesTest do
  use Absinthe.Case, async: true

  defmodule TestPrototype do
    use Absinthe.Schema.Prototype

    directive :feature do
      description "Marks a type or field as a feature"
      arg :name, non_null(:string)
      repeatable false

      on [
        :schema,
        :scalar,
        :object,
        :field_definition,
        :argument_definition,
        :interface,
        :union,
        :enum,
        :enum_value,
        :input_object,
        :input_field_definition
      ]

      expand fn args, node ->
        %{node | __private__: Keyword.put(node.__private__, :feature_name, args.name)}
      end
    end

    directive :auth do
      description "Authorization directive"
      arg :requires, non_null(:string)
      repeatable false

      on [:object, :field_definition]

      expand fn args, node ->
        %{node | __private__: Keyword.put(node.__private__, :auth_requires, args.requires)}
      end
    end

    directive :tag do
      description "A repeatable tagging directive"
      arg :name, non_null(:string)
      repeatable true

      on [:object, :field_definition, :enum, :enum_value]

      expand fn args, node ->
        existing_tags = Keyword.get(node.__private__, :tags, [])
        %{node | __private__: Keyword.put(node.__private__, :tags, [args.name | existing_tags])}
      end
    end
  end

  defmodule TestSchema do
    use Absinthe.Schema

    @prototype_schema TestPrototype

    @desc "A custom scalar with a directive"
    scalar :my_scalar do
      directive :feature, name: "custom_scalar"
      parse &Function.identity/1
      serialize &Function.identity/1
    end

    enum :role do
      directive :feature, name: "role_enum"

      value :admin, directives: [{:tag, [name: "privileged"]}]

      value :user, description: "Regular user"

      value :guest, deprecate: "Use :user instead"
    end

    interface :entity do
      directive :feature, name: "entity_interface"

      field :id, non_null(:id)

      resolve_type fn
        %{type: :user}, _ -> :user
        %{type: :post}, _ -> :post
        _, _ -> nil
      end
    end

    object :user do
      directive :feature, name: "user_object"
      directive :auth, requires: "USER"

      interface :entity

      field :id, non_null(:id)

      field :name, :string do
        directive :feature, name: "user_name_field"
      end

      field :email, :string do
        directive :auth, requires: "ADMIN"
        arg :format, :string, directives: [{:feature, [name: "format_arg"]}]
      end

      field :role, :role
      field :secret, :string, deprecate: "Use profile instead"
    end

    object :post do
      directive :tag, name: "content"
      directive :tag, name: "public"

      interface :entity

      field :id, non_null(:id)
      field :title, :string
      field :author, :user
    end

    input_object :user_input do
      directive :feature, name: "user_input_object"

      field :name, non_null(:string), directives: [{:feature, [name: "name_input_field"]}]

      field :email, :string
    end

    union :search_result do
      directive :feature, name: "search_union"

      types [:user, :post]

      resolve_type fn
        %{type: :user}, _ -> :user
        %{type: :post}, _ -> :post
        _, _ -> nil
      end
    end

    query do
      field :me, :user do
        resolve fn _, _ -> {:ok, %{id: "1", name: "Test", type: :user}} end
      end

      field :user, :user do
        arg :id, non_null(:id)
        resolve fn %{id: id}, _ -> {:ok, %{id: id, name: "User #{id}", type: :user}} end
      end

      field :search, list_of(:search_result) do
        arg :query, non_null(:string)

        resolve fn _, _ ->
          {:ok, [
            %{id: "1", name: "Test User", type: :user},
            %{id: "2", title: "Test Post", type: :post}
          ]}
        end
      end
    end

    mutation do
      field :create_user, :user do
        arg :input, non_null(:user_input)

        resolve fn %{input: input}, _ ->
          {:ok, %{id: "new", name: input.name, type: :user}}
        end
      end
    end
  end

  describe "directive definition with TypeSystem locations" do
    test "custom directive is defined with all TypeSystem locations" do
      directive = Absinthe.Schema.lookup_directive(TestSchema, :feature)

      assert directive != nil
      assert directive.name == "feature"
      assert directive.description == "Marks a type or field as a feature"

      assert :schema in directive.locations
      assert :scalar in directive.locations
      assert :object in directive.locations
      assert :field_definition in directive.locations
      assert :argument_definition in directive.locations
      assert :interface in directive.locations
      assert :union in directive.locations
      assert :enum in directive.locations
      assert :enum_value in directive.locations
      assert :input_object in directive.locations
      assert :input_field_definition in directive.locations
    end

    test "repeatable directive is properly marked" do
      tag_directive = Absinthe.Schema.lookup_directive(TestSchema, :tag)
      feature_directive = Absinthe.Schema.lookup_directive(TestSchema, :feature)

      assert tag_directive.repeatable == true
      assert feature_directive.repeatable == false
    end
  end

  describe "directive expansion on objects" do
    test "directive expands on object type" do
      type = Absinthe.Schema.lookup_type(TestSchema, :user)

      assert type != nil
      assert Keyword.get(type.__private__, :feature_name) == "user_object"
      assert Keyword.get(type.__private__, :auth_requires) == "USER"
    end

    test "multiple repeatable directives are all expanded" do
      type = Absinthe.Schema.lookup_type(TestSchema, :post)

      tags = Keyword.get(type.__private__, :tags, [])
      assert "content" in tags
      assert "public" in tags
    end
  end

  describe "directive expansion on fields" do
    test "directive expands on field definition" do
      type = Absinthe.Schema.lookup_type(TestSchema, :user)
      field = type.fields[:name]

      assert field != nil
      assert Keyword.get(field.__private__, :feature_name) == "user_name_field"
    end

    test "multiple directives expand on single field" do
      type = Absinthe.Schema.lookup_type(TestSchema, :user)
      field = type.fields[:email]

      assert field != nil
      assert Keyword.get(field.__private__, :auth_requires) == "ADMIN"
    end
  end

  describe "directive expansion on arguments" do
    test "directive expands on argument definition" do
      type = Absinthe.Schema.lookup_type(TestSchema, :user)
      field = type.fields[:email]
      arg = field.args[:format]

      assert arg != nil
      assert Keyword.get(arg.__private__, :feature_name) == "format_arg"
    end
  end

  describe "directive expansion on enums" do
    test "directive expands on enum type" do
      type = Absinthe.Schema.lookup_type(TestSchema, :role)

      assert type != nil
      assert Keyword.get(type.__private__, :feature_name) == "role_enum"
    end

    test "directive expands on enum value" do
      type = Absinthe.Schema.lookup_type(TestSchema, :role)
      admin_value = type.values[:admin]

      assert admin_value != nil
      tags = Keyword.get(admin_value.__private__, :tags, [])
      assert "privileged" in tags
    end

    test "deprecation directive works on enum values" do
      type = Absinthe.Schema.lookup_type(TestSchema, :role)
      guest_value = type.values[:guest]

      assert guest_value != nil
      assert guest_value.deprecation != nil
      assert guest_value.deprecation.reason == "Use :user instead"
    end
  end

  describe "directive expansion on interfaces" do
    test "directive expands on interface type" do
      type = Absinthe.Schema.lookup_type(TestSchema, :entity)

      assert type != nil
      assert Keyword.get(type.__private__, :feature_name) == "entity_interface"
    end
  end

  describe "directive expansion on unions" do
    test "directive expands on union type" do
      type = Absinthe.Schema.lookup_type(TestSchema, :search_result)

      assert type != nil
      assert Keyword.get(type.__private__, :feature_name) == "search_union"
    end
  end

  describe "directive expansion on scalars" do
    test "directive expands on scalar type" do
      type = Absinthe.Schema.lookup_type(TestSchema, :my_scalar)

      assert type != nil
      assert Keyword.get(type.__private__, :feature_name) == "custom_scalar"
    end
  end

  describe "directive expansion on input objects" do
    test "directive expands on input object type" do
      type = Absinthe.Schema.lookup_type(TestSchema, :user_input)

      assert type != nil
      assert Keyword.get(type.__private__, :feature_name) == "user_input_object"
    end

    test "directive expands on input field definition" do
      type = Absinthe.Schema.lookup_type(TestSchema, :user_input)
      field = type.fields[:name]

      assert field != nil
      assert Keyword.get(field.__private__, :feature_name) == "name_input_field"
    end
  end

  describe "built-in deprecated directive on fields" do
    test "deprecated directive works on fields" do
      type = Absinthe.Schema.lookup_type(TestSchema, :user)
      field = type.fields[:secret]

      assert field != nil
      assert field.deprecation != nil
      assert field.deprecation.reason == "Use profile instead"
    end
  end

  describe "execution with directives" do
    test "queries work normally with directives applied" do
      query = """
      {
        me {
          id
          name
          role
        }
      }
      """

      assert {:ok, %{data: %{"me" => %{"id" => "1", "name" => "Test", "role" => nil}}}} ==
               Absinthe.run(query, TestSchema)
    end

    test "mutations work normally with directives applied" do
      query = """
      mutation {
        createUser(input: {name: "New User"}) {
          id
          name
        }
      }
      """

      assert {:ok, %{data: %{"createUser" => %{"id" => "new", "name" => "New User"}}}} ==
               Absinthe.run(query, TestSchema)
    end
  end

  describe "introspection with applied directives" do
    test "introspection of schema directives works" do
      query = """
      {
        __schema {
          directives {
            name
            locations
            isRepeatable
          }
        }
      }
      """

      {:ok, %{data: %{"__schema" => %{"directives" => directives}}}} =
        Absinthe.run(query, TestSchema)

      feature_directive = Enum.find(directives, &(&1["name"] == "feature"))
      assert feature_directive != nil
      assert "SCHEMA" in feature_directive["locations"]
      assert "OBJECT" in feature_directive["locations"]
      assert "FIELD_DEFINITION" in feature_directive["locations"]
      assert feature_directive["isRepeatable"] == false

      tag_directive = Enum.find(directives, &(&1["name"] == "tag"))
      assert tag_directive != nil
      assert tag_directive["isRepeatable"] == true
    end

    test "type introspection shows type info" do
      query = """
      {
        __type(name: "User") {
          name
          kind
          fields(includeDeprecated: true) {
            name
            isDeprecated
            deprecationReason
          }
        }
      }
      """

      {:ok, %{data: data}} = Absinthe.run(query, TestSchema)
      user_type = data["__type"]

      assert user_type["name"] == "User"
      assert user_type["kind"] == "OBJECT"

      secret_field = Enum.find(user_type["fields"], &(&1["name"] == "secret"))
      assert secret_field["isDeprecated"] == true
      assert secret_field["deprecationReason"] == "Use profile instead"
    end

    test "introspection shows applied directives on types" do
      query = """
      {
        __type(name: "User") {
          name
          appliedDirectives {
            name
            args {
              name
              value
            }
          }
        }
      }
      """

      {:ok, %{data: %{"__type" => %{"appliedDirectives" => applied_directives}}}} =
        Absinthe.run(query, TestSchema)

      # Feature directive should be present
      feature = Enum.find(applied_directives, &(&1["name"] == "feature"))
      assert feature != nil

      name_arg = Enum.find(feature["args"], &(&1["name"] == "name"))
      assert name_arg != nil
      assert name_arg["value"] == "\"user_object\""

      # Auth directive should also be present
      auth = Enum.find(applied_directives, &(&1["name"] == "auth"))
      assert auth != nil

      requires_arg = Enum.find(auth["args"], &(&1["name"] == "requires"))
      assert requires_arg != nil
      assert requires_arg["value"] == "\"USER\""
    end

    test "introspection shows applied directives on fields" do
      query = """
      {
        __type(name: "User") {
          fields {
            name
            appliedDirectives {
              name
              args {
                name
                value
              }
            }
          }
        }
      }
      """

      {:ok, %{data: %{"__type" => %{"fields" => fields}}}} =
        Absinthe.run(query, TestSchema)

      name_field = Enum.find(fields, &(&1["name"] == "name"))
      assert name_field != nil
      applied = name_field["appliedDirectives"]
      feature = Enum.find(applied, &(&1["name"] == "feature"))
      assert feature != nil
      assert Enum.find(feature["args"], &(&1["name"] == "name" && &1["value"] == "\"user_name_field\""))
    end

    test "introspection shows applied directives on enum values" do
      query = """
      {
        __type(name: "Role") {
          enumValues {
            name
            appliedDirectives {
              name
              args {
                name
                value
              }
            }
          }
        }
      }
      """

      {:ok, %{data: %{"__type" => %{"enumValues" => enum_values}}}} =
        Absinthe.run(query, TestSchema)

      admin_value = Enum.find(enum_values, &(&1["name"] == "ADMIN"))
      assert admin_value != nil
      applied = admin_value["appliedDirectives"]
      tag = Enum.find(applied, &(&1["name"] == "tag"))
      assert tag != nil
      assert Enum.find(tag["args"], &(&1["name"] == "name" && &1["value"] == "\"privileged\""))
    end

    test "introspection shows applied directives on arguments" do
      query = """
      {
        __type(name: "User") {
          fields {
            name
            args {
              name
              appliedDirectives {
                name
                args {
                  name
                  value
                }
              }
            }
          }
        }
      }
      """

      {:ok, %{data: %{"__type" => %{"fields" => fields}}}} =
        Absinthe.run(query, TestSchema)

      email_field = Enum.find(fields, &(&1["name"] == "email"))
      assert email_field != nil

      format_arg = Enum.find(email_field["args"], &(&1["name"] == "format"))
      assert format_arg != nil

      applied = format_arg["appliedDirectives"]
      feature = Enum.find(applied, &(&1["name"] == "feature"))
      assert feature != nil
      assert Enum.find(feature["args"], &(&1["name"] == "name" && &1["value"] == "\"format_arg\""))
    end

    test "introspection shows applied directives on input object fields" do
      query = """
      {
        __type(name: "UserInput") {
          inputFields {
            name
            appliedDirectives {
              name
              args {
                name
                value
              }
            }
          }
        }
      }
      """

      {:ok, %{data: %{"__type" => %{"inputFields" => input_fields}}}} =
        Absinthe.run(query, TestSchema)

      name_field = Enum.find(input_fields, &(&1["name"] == "name"))
      assert name_field != nil

      applied = name_field["appliedDirectives"]
      feature = Enum.find(applied, &(&1["name"] == "feature"))
      assert feature != nil
      assert Enum.find(feature["args"], &(&1["name"] == "name" && &1["value"] == "\"name_input_field\""))
    end
  end
end
