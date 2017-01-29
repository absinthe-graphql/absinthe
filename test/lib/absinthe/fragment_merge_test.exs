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
          {:ok, %{todos: %{total_count: 1, completed_count: 2}}}
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
    assert {:ok, %{data: %{"viewer" => %{"todos" => [%{"totalCount" => 1, "completedCount" => 2}]}}}} == Absinthe.run(doc, Schema)
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
    assert {:ok, %{data: %{"viewer" => %{"todos" => [%{"totalCount" => 1, "completedCount" => 2}]}}}} == Absinthe.run(doc, Schema)
  end
end
