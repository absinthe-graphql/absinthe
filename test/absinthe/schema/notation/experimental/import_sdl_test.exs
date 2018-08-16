defmodule Absinthe.Schema.Notation.Experimental.ImportSdlTest do
  use Absinthe.Case
  import ExperimentalNotationHelpers

  @moduletag :experimental
  @moduletag :sdl

  defmodule Definition do
    use Absinthe.Schema

    import_sdl """
    type Query {
      posts: [Post]
    }

    type Post {
      title: String!
      body: String!
      author: User!
    }
    """

    import_sdl """
    type User {
      name: String!
    }
    """

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

  describe "multiple invocations" do
    test "can add definitions" do
      assert %{name: "User", identifier: :user} = lookup_type(Definition, :user)
    end
  end

end
