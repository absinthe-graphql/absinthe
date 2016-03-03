defmodule Absinthe.Execution.ListTest.Schema do
  use Absinthe.Schema

  object :item do
    field :categories, list_of(:string)
  end

  query do
    field :numbers, list_of(:integer), resolve: fn _, _ -> {:ok, [1,2,3]} end
    field :categories, list_of(:string) do
      resolve fn _, _ ->
        {:ok, ["foo", "bar", "baz"]}
      end
    end

    field :items, list_of(:item) do
      resolve fn _, _ ->
        items = [
          %{categories: ["foo", "bar"]},
          %{categories: ["baz", "buz"]},
        ]
        {:ok, items}
      end
    end
  end
end

defmodule Absinthe.Execution.ListTest do
  use ExSpec, async: true

  @query """
  {
    categories
  }
  """

  it "should resolve list of strings" do
    assert {:ok, %{data: %{"categories" => ["foo", "bar", "baz"]}}} ==
      Absinthe.run(@query, __MODULE__.Schema)
  end

  @query """
  {
    numbers
  }
  """

  it "should resolve list of numbers" do
    assert {:ok, %{data: %{"numbers" => [1,2,3]}}} ==
      Absinthe.run(@query, __MODULE__.Schema)
  end

  @query """
  {
    items {
      categories
    }
  }
  """

  it "should resolve list of objects with a list of scalars inside" do
    assert {:ok, %{data: %{"items" => [%{"categories" => ["foo", "bar"]}, %{"categories" => ["baz", "buz"]}]}}} ==
      Absinthe.run(@query, __MODULE__.Schema)
  end


end
