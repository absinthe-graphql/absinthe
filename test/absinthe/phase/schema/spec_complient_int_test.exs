defmodule Absinthe.Phase.Schema.SpecCompliantInt.Test do
  use Absinthe.Case, async: true

  defmodule Schema do
    use Absinthe.Schema

    @pipeline_modifier Absinthe.Phase.Schema.SpecCompliantInt

    query do
      field :parse, :integer do
        arg :input, :integer

        resolve fn args, _ ->
          {:ok, args[:input]}
        end
      end
    end
  end

  @query "query ($input: Int!) { parse(input: $input) }"

  describe "overriding built-in Int type with SpecCompliantInt" do
    test "passing valid positive int" do
      assert {
               :ok,
               %{
                 data: %{"parse" => 2_147_483_647}
               }
             } ==
               Absinthe.run(
                 @query,
                 Schema,
                 variables: %{
                   "input" => 2_147_483_647
                 }
               )
    end

    test "passing valid negative int" do
      assert {
               :ok,
               %{
                 data: %{"parse" => -2_147_483_648}
               }
             } ==
               Absinthe.run(
                 @query,
                 Schema,
                 variables: %{
                   "input" => -2_147_483_648
                 }
               )
    end

    test "passing value greater than upper bound" do
      assert {
               :ok,
               %{
                 errors: [
                   %{message: "Argument \"input\" has invalid value $input."}
                 ]
               }
             } =
               Absinthe.run(
                 @query,
                 Schema,
                 variables: %{
                   "input" => 2_147_483_648
                 }
               )
    end

    test "passing value smaller than lower bound" do
      assert {
               :ok,
               %{
                 errors: [
                   %{message: "Argument \"input\" has invalid value $input."}
                 ]
               }
             } =
               Absinthe.run(
                 @query,
                 Schema,
                 variables: %{
                   "input" => -2_147_483_649
                 }
               )
    end
  end
end
