defmodule Absinthe.Schema.Notation.Experimental.ImportSdlTest do
  use Absinthe.Case
  import ExperimentalNotationHelpers

  @moduletag :experimental
  @moduletag :sdl

  defmodule Definition do
    use Absinthe.Schema

    import_sdl("""
    type Query {
      "A list of posts"
      posts: [Post]
      admin: User!
    }

    "A submitted post"
    type Post {
      title: String!
      body: String!
      \"""
      The post author
      (is a user)
      \"""
      author: User!
    }
    """)

    import_sdl("""
    type User {
      name: String!
    }
    """)

    def get_posts(_, _, _) do
      [
        %{title: "Foo", body: "A body.", author: %{name: "Bruce"}},
        %{title: "Bar", body: "A body.", author: %{name: "Ben"}}
      ]
    end

    def decorations(%{identifier: :admin}, [%{identifier: :query}|_]) do
      {:description, "The admin"}
    end
    # TODO: This doesn't work yeta
    # def decorations(%{identifier: :posts}, [%{identifier: :query}|_]) do
    #   {:resolve, &get_posts/3}
    # end
    def decorations(_node, _) do
      []
    end

  end

  describe "query root type" do
    test "is defined" do
      assert %{name: "Query", identifier: :query} = lookup_type(Definition, :query)
    end

    test "defines fields" do
      assert %{name: "posts"} = lookup_field(Definition, :query, :posts)
    end
  end

  describe "non-root type" do
    test "is defined" do
      assert %{name: "Post", identifier: :post} = lookup_type(Definition, :post)
    end

    test "defines fields" do
      assert %{name: "title"} = lookup_field(Definition, :post, :title)
      assert %{name: "body"} = lookup_field(Definition, :post, :body)
    end
  end

  describe "descriptions" do

    test "work on objects" do
      assert %{description: "A submitted post"} = lookup_type(Definition, :post)
    end

    test "work on fields" do
      assert %{description: "A list of posts"} = lookup_field(Definition, :query, :posts)
    end

    test "can be multiline" do
      assert %{description: "The post author\n(is a user)"} =
               lookup_field(Definition, :post, :author)
    end

    test "can be added by a decoration" do
      assert %{description: "The admin"} = lookup_compiled_field(Definition, :query, :admin)
    end
  end

  describe "multiple invocations" do
    test "can add definitions" do
      assert %{name: "User", identifier: :user} = lookup_type(Definition, :user)
    end
  end

  @query """
  { admin { name } }
  """

  describe "execution with root_value" do
    test "works" do
      assert {:ok, %{data: %{"admin" => %{"name" => "Bruce"}}}} =
               Absinthe.run(@query, Definition, root_value: %{admin: %{name: "Bruce"}})
    end
  end

  @query """
  { posts { title } }
  """

  describe "execution with decoration-defined resolvers" do

    @tag :pending_schema
    test "works" do
      assert {:ok, %{data: %{"posts" => [%{"title" => "Foo"}, %{"title" => "Bar"}]}}} =
              Absinthe.run(@query, Definition)
    end
  end
end
