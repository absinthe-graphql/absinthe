defmodule Absinthe.FragmentMergeTest do
  use Absinthe.Case, async: true

  defmodule Schema do
    use Absinthe.Schema

    object :user do
      field :todos, list_of(:todo)
    end

    object :todo do
      field :total_count, :integer
      field :completed_count, :integer
    end

    query do
      field :viewer, :user do
        resolve fn _, _ ->
          {:ok,
           %{
             todos: [%{total_count: 1, completed_count: 2}, %{total_count: 3, completed_count: 4}]
           }}
        end
      end
    end
  end

  test "it deep merges fields properly" do
    doc = """
    {
      viewer {
        ...fragmentWithOneField
        ...fragmentWithOtherField
      }
    }

    fragment fragmentWithOneField on User {
      todos {
        totalCount,
      }
    }

    fragment fragmentWithOtherField on User {
      todos {
        completedCount
      }
    }
    """

    expected = %{
      "viewer" => %{
        "todos" => [
          %{"totalCount" => 1, "completedCount" => 2},
          %{"totalCount" => 3, "completedCount" => 4}
        ]
      }
    }

    assert {:ok, %{data: expected}} == Absinthe.run(doc, Schema)
  end

  test "it deep merges duplicated fields properly" do
    doc = """
    {
      viewer {
        ...fragmentWithOtherField
        ...fragmentWithOneField
      }
    }

    fragment fragmentWithOneField on User {
      todos {
        totalCount,
        completedCount
      }
    }

    fragment fragmentWithOtherField on User {
      todos {
        completedCount
      }
    }
    """

    expected = %{
      "viewer" => %{
        "todos" => [
          %{"totalCount" => 1, "completedCount" => 2},
          %{"totalCount" => 3, "completedCount" => 4}
        ]
      }
    }

    assert {:ok, %{data: expected}} == Absinthe.run(doc, Schema)
  end

  test "it deep merges fields properly different levels" do
    doc = """
    {
      viewer {
        ...fragmentWithOneField
      }
      ...fragmentWithOtherField
    }

    fragment fragmentWithOneField on User {
      todos {
        totalCount,
      }
    }

    fragment fragmentWithOtherField on RootQueryType {
      viewer {
        todos {
          completedCount
        }
      }
    }
    """

    expected = %{
      "viewer" => %{
        "todos" => [
          %{"totalCount" => 1, "completedCount" => 2},
          %{"totalCount" => 3, "completedCount" => 4}
        ]
      }
    }

    assert {:ok, %{data: expected}} == Absinthe.run(doc, Schema)
  end
end
