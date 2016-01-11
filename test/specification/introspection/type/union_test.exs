defmodule Absinthe.Specification.Introspection.Type.UnionTest do
  use ExSpec, async: true
  import AssertResult

  @moduletag :specification

  describe "introspection of a union type" do

    it "can use __type and get possible types" do
      result = """
      {
        __type(name: "SearchResult") {
          kind
          name
          description
          possibleTypes {
            name
          }
        }
      }
      """
      |> Absinthe.run(ContactSchema)
      assert_result {:ok, %{data: %{"__type" => %{"name" => "SearchResult", "description" => "A search result", "kind" => "UNION", "possibleTypes" => [%{"name" => "Person"}, %{"name" => "Business"}]}}}}, result
    end

  end

end
