defmodule Absinthe.Execution.ListTest.Schema do
  use Absinthe.Schema

  object :item do
    field :id, :string
    field :name, :string
    field :categories, list_of(:string)
    field :preview_url, :string
    field :download_url, :string
  end

  query do
    field :items, list_of(:item) do
      arg :category, :string

      resolve fn _, _ ->
        items = [
          %{
            categories: ["foo", "bar", "baz"]
          }
        ]
        {:ok, items}
      end
    end
  end
end

defmodule Absinthe.Execution.ListTest do
  use ExSpec, async: true
  alias __MODULE__

  @query """
  {
    items {
      categories
    }
  }
  """

  it "should not blow up" do
    Absinthe.run(@query, __MODULE__.Schema)
    |> IO.inspect
  end

end
