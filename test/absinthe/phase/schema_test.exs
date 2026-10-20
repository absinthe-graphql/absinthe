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

  defmodule NameAliasSchema do
    use Absinthe.Schema

    input_object :string_op do
      field :eq, :string
      field :neq, :string, name: "notEq"
      field :not_in, list_of(non_null(:string))
    end

    query do
      field :ping, :string do
        arg :filter, :string_op
        arg :country_code, :string, name: "countryCode"
        resolve fn _, args, _ -> {:ok, inspect(args)} end
      end
    end
  end

  describe "name: alias on input object fields and arguments" do
    test "input object field with `name:` alias is accepted" do
      {:ok, result} =
        Absinthe.run(
          "query Q($f: StringOp) { ping(filter: $f) }",
          NameAliasSchema,
          variables: %{"f" => %{"notEq" => "PL"}}
        )

      assert %{data: %{"ping" => out}} = result
      assert out =~ ~s(neq: "PL")
    end

    test "default snake_case identifier still works via camelCase wire name" do
      {:ok, result} =
        Absinthe.run(
          "query Q($f: StringOp) { ping(filter: $f) }",
          NameAliasSchema,
          variables: %{"f" => %{"notIn" => ["PL", "DE"]}}
        )

      assert %{data: %{"ping" => out}} = result
      assert out =~ ~s(not_in: ["PL", "DE"])
    end

    test "argument with `name:` alias still works" do
      {:ok, result} = Absinthe.run("{ ping(countryCode: \"PL\") }", NameAliasSchema)
      assert %{data: %{"ping" => out}} = result
      assert out =~ ~s(country_code: "PL")
    end

    test "genuinely unknown input field still errors" do
      {:ok, result} =
        Absinthe.run(
          "query Q($f: StringOp) { ping(filter: $f) }",
          NameAliasSchema,
          variables: %{"f" => %{"bogusField" => "X"}}
        )

      assert %{errors: [%{message: msg}]} = result
      assert msg =~ ~s(In field "bogusField": Unknown field)
    end
  end
end
