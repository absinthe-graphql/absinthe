defmodule Absinthe.Specification.Introspection.Schema.ObjectTest do
  use ExSpec, async: true
  import AssertResult

  alias Absinthe.Type

  describe "introspection of an object type" do

    it "can use __Type" do
      result = """
      {
        __Type(name: "Person") {
          kind
          name
          description
          fields {
            name
          }
        }
      }
      """
      |> Absinthe.run(ContactSchema)
      assert_result {:ok, %{data: %{"__Type" => %{"name" => "Person", "description" => "A person", "kind" => "OBJECT", "fields" => [%{"name" => "name"}, %{"name" => "age"}]}}}}, result
    end
  end

end
