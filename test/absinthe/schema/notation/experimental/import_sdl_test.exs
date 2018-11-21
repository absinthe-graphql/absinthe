defmodule Absinthe.Schema.Notation.Experimental.ImportSdlTest do
  use Absinthe.Case
  import ExperimentalNotationHelpers

  @moduletag :experimental
  @moduletag :sdl

  defmodule Definition do
    use Absinthe.Schema

    # Embedded SDL
    import_sdl """
    type Query {
      "A list of posts"
      posts(filter: PostFilter, reverse: Boolean): [Post]
      admin: User!
    }

    type Comment {
      author: User!
      subject: Post!
      order: Int
    }

    enum Category {
      NEWS
      OPINION
    }

    enum PostState {
      SUBMITTED
      ACCEPTED
      REJECTED
    }

    interface Named {
      name: String!
    }

    interface Titled {
      title: String!
    }

    scalar A
    scalar B

    union SearchResult = Post | User
    union Content = Post | Comment
    """

    # Read SDL from file manually at compile-time
    import_sdl File.read!("test/support/fixtures/import_sdl_binary_fn.graphql")

    # Read from file at compile time (with support for automatic recompilation)
    import_sdl path: "test/support/fixtures/import_sdl_path_option.graphql"
    import_sdl path: Path.join("test/support", "fixtures/import_sdl_path_option_fn.graphql")

    def get_posts(_, _, _) do
      posts = [
        %{title: "Foo", body: "A body.", author: %{name: "Bruce"}},
        %{title: "Bar", body: "A body.", author: %{name: "Ben"}}
      ]

      {:ok, posts}
    end

    def upcase_title(post, _, _) do
      {:ok, Map.get(post, :title) |> String.upcase()}
    end

    def decorations(%{identifier: :admin}, [%{identifier: :query} | _]) do
      {:description, "The admin"}
    end

    def decorations(%{identifier: :filter}, [%{identifier: :posts} | _]) do
      {:description, "A filter argument"}
    end

    def decorations(%{identifier: :posts}, [%{identifier: :query} | _]) do
      {:resolve, &__MODULE__.get_posts/3}
    end

    def decorations(%Absinthe.Blueprint{}, _) do
      %{
        query: %{
          posts: %{
            reverse: {:description, "Just reverse the list, if you want"}
          }
        },
        post: %{
          upcased: [
            {:description, "The title, but upcased"},
            {:resolve, &__MODULE__.upcase_title/3}
          ]
        }
      }
    end

    def decorations(_node, _ancestors) do
      []
    end
  end

  describe "locations" do
    test "have evaluated file values" do
      Absinthe.Blueprint.prewalk(Definition.__absinthe_blueprint__(), nil, fn
        %{__reference__: %{location: %{file: file}}} = node, _ ->
          assert is_binary(file)
          {node, nil}
        node, _ ->
          {node, nil}
      end)
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

    test "work on fields, defined deeply" do
      assert %{description: "The title, but upcased"} = lookup_compiled_field(Definition, :post, :upcased)
    end

    test "work on arguments, defined deeply" do
      assert %{description: "Just reverse the list, if you want"} = lookup_compiled_argument(Definition, :query, :posts, :reverse)
    end

    test "can be multiline" do
      assert %{description: "The post author\n(is a user)"} =
               lookup_field(Definition, :post, :author)
    end

    test "can be added by a decoration to a field" do
      assert %{description: "The admin"} = lookup_compiled_field(Definition, :query, :admin)
    end

    test "can be added by a decoration to an argument" do
      field = lookup_compiled_field(Definition, :query, :posts)
      assert %{description: "A filter argument"} = field.args.filter
    end
  end

  describe "resolve" do

    test "work on fields, defined deeply" do
      assert %{middleware: mw} = lookup_compiled_field(Definition, :post, :upcased)
      assert length(mw) > 0
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
    test "works" do
      assert {:ok, %{data: %{"posts" => [%{"title" => "Foo"}, %{"title" => "Bar"}]}}} =
               Absinthe.run(@query, Definition)
    end
  end

  @query """
  { posts { upcased } }
  """
  describe "execution with deeply decoration-defined resolvers" do
    test "works" do
      assert {:ok, %{data: %{"posts" => [%{"upcased" => "FOO"}, %{"upcased" => "BAR"}]}}} =
               Absinthe.run(@query, Definition)
    end
  end


  describe "Absinthe.Schema.used_types/1" do
    test "works" do
      assert Absinthe.Schema.used_types(Definition)
    end
  end
end
