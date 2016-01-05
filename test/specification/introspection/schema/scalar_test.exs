defmodule Absinthe.Specification.Introspection.Schema.ScalarTest do
  use ExSpec, async: true
  import AssertResult

  alias Absinthe.Type

  defmodule MySchema do
    use Absinthe.Schema

    def query do
      %Type.Object{
        fields: fields(
          greeting: [
            type: :string,
            description: "A traditional greeting",
            resolve: fn
              _, _ -> {:ok, "Hah!"}
            end
          ]
        )
      }
    end
  end

  describe "introspection of a scalar type" do
    @tag :tester
    it "can use __Type" do
      result = """
      {
        __Type(name: "String") {
          kind
          name
          description,
          fields
        }
      }
      """
      |> Absinthe.run(MySchema)
      assert_result {:ok, %{data: %{"__Type" => %{"name" => Type.Scalar.string.name, "description" => Type.Scalar.string.description, "kind" => "SCALAR", "fields" => nil}}}}, result
    end
  end

end
