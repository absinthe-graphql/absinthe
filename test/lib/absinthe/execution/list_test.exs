defmodule Absinthe.Execution.ListTest.Schema do
  use Absinthe.Schema

  object :item do
    field :categories, list_of(:string)
  end

  object :book do
    field :name, :string
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

    field :list_of_list_of_numbers, list_of(list_of(:integer)) do
      resolve fn _, _ -> {:ok, [[1, 2, 3], [4, 5, 6]]} end
    end

    field :big_nesting_of_numbers, list_of(list_of(list_of(list_of(:integer)))) do
      resolve fn _, _ ->
        list = [[
          [
            [1, 2, 3], [4, 5, 6]
          ],
          [
            [7, 8, 9]
          ],
          [
            [10, 11, 12]
          ]
        ]]
        {:ok, list}
      end
    end

    field :list_of_list_of_books, list_of(list_of(:book)) do
      resolve fn _, _ ->
        books = [[
          %{name: "foo"},
          %{name: "bar"},
        ], [
          %{name: "baz"},
        ]]
        {:ok, books}
      end
    end

    field :list_of_list_of_items, list_of(list_of(:item)) do
      resolve fn _, _ ->
        items = [[
          %{categories: ["foo", "bar"]},
          %{categories: ["baz", "buz"]},
        ], [
          %{categories: ["blip", "blop"]},
        ]]
        {:ok, items}
      end
    end
  end
end

defmodule Absinthe.Execution.ListTest do
  use Absinthe.Case, async: true

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

  @query """
  {
    listOfListOfNumbers
  }
  """
  it "should resolve list of list of numbers" do
    assert {:ok, %{data: %{"listOfListOfNumbers" => [[1,2,3],[4,5,6]]}}} ==
      Absinthe.run(@query, __MODULE__.Schema)
  end

  @query """
  {
    bigNestingOfNumbers
  }
  """
  it "should resolve list of lists of... numbers with a depth of 4" do
    list = [[
      [
        [1, 2, 3], [4, 5, 6]
      ],
      [
        [7, 8, 9]
      ],
      [
        [10, 11, 12]
      ]
    ]]
    assert {:ok, %{data: %{"bigNestingOfNumbers" => list}}} ==
      Absinthe.run(@query, __MODULE__.Schema)
  end

  @query """
  {
    listOfListOfBooks {
      name
    }
  }
  """
  it "should resolve list of list of books" do
    books = [[
      %{"name" => "foo"},
      %{"name" => "bar"},
    ], [
      %{"name" => "baz"},
    ]]
    assert {:ok, %{data: %{"listOfListOfBooks" => books}}} ==
      Absinthe.run(@query, __MODULE__.Schema)
  end

  @query """
  {
    listOfListOfItems {
      categories
    }
  }
  """
  it "should resolve list of list of items" do
    items = [[
      %{"categories" => ["foo", "bar"]},
      %{"categories" => ["baz", "buz"]},
    ], [
      %{"categories" => ["blip", "blop"]},
    ]]
    assert {:ok, %{data: %{"listOfListOfItems" => items}}} ==
      Absinthe.run(@query, __MODULE__.Schema)
  end

end
