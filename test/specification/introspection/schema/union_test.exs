defmodule Absinthe.Specification.Introspection.Schema.UnionTest do
  use ExSpec, async: true
  import AssertResult

  describe "introspection of an object type" do

    it "can use __Type and get possible types" do
      result = """
      {
        __Type(name: "SearchResult") {
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
      assert_result {:ok, %{data: %{"__Type" => %{"name" => "SearchResult", "description" => "A search result", "kind" => "UNION", "possible_types" => [%{"name" => "Person"}, %{"name" => "Business"}]}}}}, result
    end

  end

end
