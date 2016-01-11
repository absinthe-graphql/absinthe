defmodule Absinthe.Specification.Introspection.Schema.UnionTest do
  use ExSpec, async: true
  import AssertResult

  describe "introspection of a union type" do

    it "can use __type and get possible types" do
      result = """
      {
        __type(name: "SearchResult") {
          kind
          name
          description
          possible_types {
            name
          }
        }
      }
      """
      |> Absinthe.run(ContactSchema)
      assert_result {:ok, %{data: %{"__type" => %{"name" => "SearchResult", "description" => "A search result", "kind" => "UNION", "possible_types" => [%{"name" => "Person"}, %{"name" => "Business"}]}}}}, result
    end

  end

end
