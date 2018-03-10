defmodule Absinthe.Phase.SchemaTest do
  use Absinthe.Case, async: true

  defmodule IntegerInputSchema do
    use Absinthe.Schema

    query do
      field :test, :string do
        arg :integer, :integer

        resolve fn _, _, _ ->
          {:ok, "ayup"}
        end
      end
    end
  end

  describe "when given [Int] for Int schema node" do
    @query """
    { test(integer: [1]) }
    """

    test "doesn't raise an exception" do
      assert {:ok, _} = run(@query)
    end
  end

  def run(query) do
    with {:ok, value} <- Absinthe.Phase.Parse.run(query),
         {:ok, value} <- Absinthe.Phase.Blueprint.run(value) do
      Absinthe.Phase.Schema.run(value, schema: IntegerInputSchema)
    end
  end
end
