defmodule Absinthe.UnionFragmentTest do
  use Absinthe.Case, async: true

  @root %{
    menu_items: [
      %{type: :menu_item, id: 1, added_by: %{username: "Ben", id: 1}, name: "Coffee"}
    ],
    categories: [
      %{type: :category, id: 1, added_by: %{username: "Ben", id: 1}, name: "Drinks"}
    ]
  }

  defmodule Schema do
    use Absinthe.Schema

    object :menu_item do
      field :id, :id
      field :name, :string
      field :added_by, :user
    end

    object :category do
      field :id, :id
      field :name, :string
      field :added_by, :user
    end

    union :search_result do
      types [:menu_item, :category]

      resolve_type fn %{type: type}, _ -> type end
    end

    object :user do
      field :name, :string do
        resolve fn user, _, _ -> {:ok, user.username} end
      end

      field :id, :id

      field :todos, list_of(:todo)
      interface :named
    end

    object :todo do
      field :name, :string do
        resolve fn todo, _, _ -> {:ok, todo.title} end
      end

      field :completed, :boolean
      interface :named
      interface :completable
    end

    union :object do
      types [:user, :todo]
      resolve_type fn %{type: type}, _ -> type end
    end

    interface :named do
      field :name, :string
      resolve_type fn %{type: type}, _ -> type end
    end

    interface :completable do
      field :completed, :boolean
      resolve_type fn %{type: type}, _ -> type end
    end

    object :viewer do
      field :objects, list_of(:object)
      field :me, :user
      field :named_thing, :named
    end

    query do
      field :search, list_of(:search_result) do
        resolve fn root, _, _ ->
          {:ok, root.menu_items ++ root.categories}
        end
      end

      field :viewer, :viewer do
        resolve fn _, _ ->
          {:ok,
           %{
             objects: [
               %{type: :user, username: "foo", completed: true},
               %{type: :todo, title: "do stuff", completed: false},
               %{type: :user, username: "bar"}
             ],
             me: %{type: :user, username: "baz", todos: [], name: "should not be exposed"},
             named_thing: %{type: :todo, title: "do stuff", completed: false}
           }}
        end
      end
    end
  end

  test "different sub types with the same internal field names don't cause conflict" do
    doc = """
    {
      search {
        ... on MenuItem {
          addedBy { name }
        }
        ... on Category {
          addedBy { name id }
        }
      }
    }

    """

    expected = %{
      "search" => [
        %{"addedBy" => %{"name" => "Ben"}},
        %{"addedBy" => %{"name" => "Ben", "id" => "1"}}
      ]
    }

    assert {:ok, %{data: expected}} == Absinthe.run(doc, Schema, root_value: @root)
  end

  test "it queries a heterogeneous list properly" do
    doc = """
    {
      viewer {
        objects {
          ... on User {
            __typename
            name
          }
          ... on Todo {
            __typename
            completed
          }
        }
      }
    }

    """

    expected = %{
      "viewer" => %{
        "objects" => [
          %{"__typename" => "User", "name" => "foo"},
          %{"__typename" => "Todo", "completed" => false},
          %{"__typename" => "User", "name" => "bar"}
        ]
      }
    }

    assert {:ok, %{data: expected}} == Absinthe.run(doc, Schema, root_value: @root)
  end

  test "it queries an interface with the concrete type's field resolvers" do
    doc = """
    {
      viewer {
        me {
          ... on Named {
            __typename
            name
          }
        }
      }
    }

    """

    expected = %{"viewer" => %{"me" => %{"__typename" => "User", "name" => "baz"}}}
    assert {:ok, %{data: expected}} == Absinthe.run(doc, Schema, root_value: @root)
  end

  test "it queries an interface implemented by a union type" do
    doc = """
    {
      viewer {
        objects {
          ... on Named {
            __typename
            name
          }
        }
      }
    }

    """

    expected = %{
      "viewer" => %{
        "objects" => [
          %{"__typename" => "User", "name" => "foo"},
          %{"__typename" => "Todo", "name" => "do stuff"},
          %{"__typename" => "User", "name" => "bar"}
        ]
      }
    }

    assert {:ok, %{data: expected}} == Absinthe.run(doc, Schema, root_value: @root)
  end

  test "it queries an interface on an unrelated interface" do
    doc = """
    {
      viewer {
        namedThing {
          __typename
          name
          ... on Completable {
            completed
          }
        }
      }
    }

    """

    expected = %{
      "viewer" => %{
        "namedThing" => %{"__typename" => "Todo", "name" => "do stuff", "completed" => false}
      }
    }

    assert {:ok, %{data: expected}} == Absinthe.run(doc, Schema, root_value: @root)
  end
end
