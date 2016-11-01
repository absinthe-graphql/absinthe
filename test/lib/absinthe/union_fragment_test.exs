defmodule Absinthe.UnionFragmentTest do
  use Absinthe.Case, async: true

  defmodule Schema do
    use Absinthe.Schema

    object :user do
      field :name, :string
      field :todos, list_of(:todo)
    end

    object :todo do
      field :name, :string
      field :completed, :boolean
    end

    union :object do
      types [:user, :todo]
      resolve_type fn %{type: type}, _ -> type end
    end

    object :viewer do
      field :objects, list_of(:object)
    end

    query do
      field :viewer, :viewer do
        resolve fn _, _ ->
          {:ok, %{objects: [
            %{type: :user, name: "foo", completed: true},
            %{type: :todo, name: "do stuff", completed: false},
            %{type: :user, name: "bar"},
          ]}}
        end
      end
    end
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
    expected = %{"viewer" => %{"objects" => [
      %{"__typename" => "User", "name" => "foo"},
      %{"__typename" => "Todo", "completed" => false},
      %{"__typename" => "User", "name" => "bar"},
    ]}}
    assert {:ok, %{data: expected}} == Absinthe.run(doc, Schema)
  end

end
