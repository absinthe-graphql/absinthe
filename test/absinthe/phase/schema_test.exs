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
    pipeline =
      IntegerInputSchema
      |> Absinthe.Pipeline.for_document([])
      |> Absinthe.Pipeline.before(Absinthe.Phase.Schema)

    with {:ok, bp, _} <- Absinthe.Pipeline.run(query, pipeline) do
      Absinthe.Phase.Schema.run(bp, schema: IntegerInputSchema)
    end
  end
end
