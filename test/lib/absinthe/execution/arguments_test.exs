defmodule Absinthe.Execution.ArgumentsTest do
  use ExSpec, async: true

  import AssertResult

  defmodule Schema do
    use Absinthe.Schema

    @res %{
      true => "YES",
      false => "NO"
    }

    query do

      field :something,
        type: :string,
        args: [
          flag: [type: :boolean, default_value: false]
        ],
        resolve: fn
          %{flag: val}, _ ->
            {:ok, @res[val]}
          _, _ ->
            {:error, "No value provided for flag argument"}
        end

    end

  end

  describe "boolean arguments" do

    it "are passed as arguments to resolution functions correctly" do
      assert_result {:ok, %{data: %{"something" => "YES"}}}, "{ something(flag: true) }" |> Absinthe.run(Schema)
      assert_result {:ok, %{data: %{"something" => "NO"}}}, "{ something(flag: false) }" |> Absinthe.run(Schema)
      assert_result {:ok, %{data: %{"something" => "NO"}}}, "{ something }" |> Absinthe.run(Schema)
    end

  end

end
