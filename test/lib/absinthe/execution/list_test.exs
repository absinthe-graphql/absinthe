defmodule Absinthe.Execution.ListTest.Schema do
  use Absinthe.Schema

  query do
    field :categories, list_of(:string) do
      resolve fn _, _ ->
        {:ok, ["foo", "bar", "baz"]}
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

  it "should not blow up" do
    Absinthe.run(@query, __MODULE__.Schema)
    |> IO.inspect
  end

end
