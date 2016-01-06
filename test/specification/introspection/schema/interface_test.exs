defmodule Absinthe.Specification.Introspection.Schema.InterfaceTest do
  use ExSpec, async: true
  import AssertResult

  describe "introspection of an interface type" do

    it "can use __Type and get possible types" do
      result = """
      {
        __Type(name: "NamedEntity") {
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
      assert_result {:ok, %{data: %{"__Type" => %{"name" => "NamedEntity", "description" => "A named entity", "kind" => "INTERFACE", "possible_types" => [%{"name" => "Person"}, %{"name" => "Business"}]}}}}, result
    end

  end

end
