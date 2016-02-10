defmodule Absinthe.Specification.Introspection.Type.ScalarTest do
  use ExSpec, async: true
  import AssertResult

  alias Absinthe.Type

  @moduletag :specification

  defmodule MySchema do
    use Absinthe.Schema

    query [
      fields: [
        greeting: [
          type: :string,
          description: "A traditional greeting",
          resolve: fn
            _, _ -> {:ok, "Hah!"}
          end
        ]
      ]
    ]

  end

  describe "introspection of a scalar type" do
    it "can use __type" do
      result = """
      {
        __type(name: "String") {
          kind
          name
          description,
          fields
        }
      }
      """
      |> Absinthe.run(MySchema)
      assert_result {:ok, %{data: %{"__type" => %{"name" => Type.Scalar.string.name, "description" => Type.Scalar.string.description, "kind" => "SCALAR", "fields" => nil}}}}, result
    end
  end

end
