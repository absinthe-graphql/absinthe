defmodule Absinthe.Execution.ArgumentsTest do
  use ExSpec, async: true

  import AssertResult

  defmodule Schema do
    use Absinthe.Schema
    alias Absinthe.Type

    @res %{true => "YES", false => "NO"}

    def query do
      %Type.Object{
        fields: fields(
          something: [
            type: :string,
            args: args(
              flag: [type: :boolean, default_value: false]
            ),
            resolve: fn
              %{flag: val}, _ ->
                {:ok, @res[val]}
              _, _ ->
                {:error, "No value provided for flag argument"}
            end
          ]
        )
      }
    end

  end

  describe "boolean arguments" do

    @tag :boolean
    it "are passed as arguments to resolution functions correctly" do
      assert_result {:ok, %{data: %{"something" => "YES"}}}, "{ something(flag: true) }" |> Absinthe.run(Schema)
      assert_result {:ok, %{data: %{"something" => "NO"}}}, "{ something(flag: false) }" |> Absinthe.run(Schema)
      assert_result {:ok, %{data: %{"something" => "NO"}}}, "{ something }" |> Absinthe.run(Schema)
    end

  end

end
