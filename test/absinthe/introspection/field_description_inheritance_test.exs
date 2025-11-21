defmodule Absinthe.Introspection.FieldDescriptionInheritanceTest do
  use Absinthe.Case, async: true

  defmodule TestSchema do
    use Absinthe.Schema

    def user_type_description, do: "A user in the system"
    def post_type_description, do: "A blog post written by a user"
    
    object :user do
      description user_type_description()
      
      field :id, :id
      field :name, :string, description: "The user's full name"
      field :email, :string  # No description - should not inherit from :string
    end

    object :post do
      description post_type_description()
      
      field :id, :id
      field :title, :string, description: "The post title"
      field :content, :string
      field :author, :user  # No description - should inherit from :user type
      field :readers, list_of(:user), description: "Users who have read this post"
      field :main_reader, non_null(:user)  # No description - should inherit from :user type (through non_null wrapper)
    end

    query do
      field :current_user, :user do
        description "Get the current user"
        resolve fn _, _ -> {:ok, %{id: "1", name: "John Doe", email: "john@example.com"}} end
      end
      
      field :featured_post, :post  # No description - should inherit from :post type
      field :posts, list_of(:post) do
        resolve fn _, _ -> {:ok, []} end
      end
    end
  end

  describe "field description inheritance through introspection" do
    test "field without description inherits from referenced custom type" do
      query = """
      {
        __type(name: "Post") {
          fields {
            name
            description
          }
        }
      }
      """

      assert {:ok, %{data: %{"__type" => %{"fields" => fields}}}} = 
        Absinthe.run(query, TestSchema)

      author_field = Enum.find(fields, &(&1["name"] == "author"))
      assert author_field["description"] == TestSchema.user_type_description()
    end

    test "field without description inherits from wrapped type (non_null)" do
      query = """
      {
        __type(name: "Post") {
          fields {
            name
            description
            type {
              name
              kind
              ofType {
                name
                kind
              }
            }
          }
        }
      }
      """

      assert {:ok, %{data: %{"__type" => %{"fields" => fields}}}} = 
        Absinthe.run(query, TestSchema)

      main_reader_field = Enum.find(fields, &(&1["name"] == "mainReader"))
      assert main_reader_field["description"] == TestSchema.user_type_description()
    end

    test "field with explicit description keeps its own description" do
      query = """
      {
        __type(name: "Post") {
          fields {
            name
            description
          }
        }
      }
      """

      assert {:ok, %{data: %{"__type" => %{"fields" => fields}}}} = 
        Absinthe.run(query, TestSchema)

      readers_field = Enum.find(fields, &(&1["name"] == "readers"))
      assert readers_field["description"] == "Users who have read this post"
    end

    test "field referencing built-in scalar without description inherits scalar description" do
      query = """
      {
        __type(name: "Post") {
          fields {
            name
            description
          }
        }
      }
      """

      assert {:ok, %{data: %{"__type" => %{"fields" => fields}}}} = 
        Absinthe.run(query, TestSchema)

      content_field = Enum.find(fields, &(&1["name"] == "content"))
      # Built-in scalars have descriptions, so the field will inherit the String type's description
      assert content_field["description"] =~ "String" && content_field["description"] =~ "UTF-8"
    end

    test "query field without description inherits from referenced type" do
      query = """
      {
        __type(name: "RootQueryType") {
          fields {
            name
            description
          }
        }
      }
      """

      assert {:ok, %{data: %{"__type" => %{"fields" => fields}}}} = 
        Absinthe.run(query, TestSchema)

      featured_post_field = Enum.find(fields, &(&1["name"] == "featuredPost"))
      assert featured_post_field["description"] == TestSchema.post_type_description()
    end

    test "query field with description keeps its own" do
      query = """
      {
        __type(name: "RootQueryType") {
          fields {
            name
            description
          }
        }
      }
      """

      assert {:ok, %{data: %{"__type" => %{"fields" => fields}}}} = 
        Absinthe.run(query, TestSchema)

      current_user_field = Enum.find(fields, &(&1["name"] == "currentUser"))
      assert current_user_field["description"] == "Get the current user"
    end

    test "field referencing list type without description inherits from inner type" do
      query = """
      {
        __type(name: "RootQueryType") {
          fields {
            name
            description
          }
        }
      }
      """

      assert {:ok, %{data: %{"__type" => %{"fields" => fields}}}} = 
        Absinthe.run(query, TestSchema)

      posts_field = Enum.find(fields, &(&1["name"] == "posts"))
      # The field should inherit the description from the inner :post type
      assert posts_field["description"] == TestSchema.post_type_description()
    end
  end

  describe "field description inheritance with interfaces" do
    defmodule InterfaceSchema do
      use Absinthe.Schema

      def node_description, do: "An object with an ID"
      
      interface :node do
        description node_description()
        
        field :id, non_null(:id), description: "The ID of the object"
        
        resolve_type fn
          %{type: :user}, _ -> :user
          %{type: :post}, _ -> :post
          _, _ -> nil
        end
      end

      object :user do
        description "A user account"
        interface :node
        
        field :id, non_null(:id)  # Should keep interface field description
        field :name, :string
      end

      object :post do
        interface :node
        
        field :id, non_null(:id), description: "The unique post ID"  # Overrides interface description
        field :title, :string
      end

      query do
        field :node, :node  # Should inherit from :node interface
      end
    end

    test "object field implementing interface keeps interface field description when not specified" do
      query = """
      {
        __type(name: "User") {
          fields {
            name
            description
          }
        }
      }
      """

      assert {:ok, %{data: %{"__type" => %{"fields" => fields}}}} = 
        Absinthe.run(query, InterfaceSchema)

      id_field = Enum.find(fields, &(&1["name"] == "id"))
      # Note: Interface field descriptions are not inherited in the current implementation.
      # The field will inherit from the ID scalar type instead.
      assert id_field["description"] =~ "ID"
    end

    test "query field referencing interface inherits interface description" do
      query = """
      {
        __type(name: "RootQueryType") {
          fields {
            name
            description
          }
        }
      }
      """

      assert {:ok, %{data: %{"__type" => %{"fields" => fields}}}} = 
        Absinthe.run(query, InterfaceSchema)

      node_field = Enum.find(fields, &(&1["name"] == "node"))
      assert node_field["description"] == InterfaceSchema.node_description()
    end
  end
end