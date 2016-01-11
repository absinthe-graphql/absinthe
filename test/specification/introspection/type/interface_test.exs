defmodule Absinthe.Specification.Introspection.Type.InterfaceTest do
  use ExSpec, async: true
  import AssertResult

  @moduletag :specification

  describe "introspection of an interface type" do

    it "can use __type and get possible types" do
      result = """
      {
        __type(name: "NamedEntity") {
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
      assert_result {:ok, %{data: %{"__type" => %{"name" => "NamedEntity", "description" => "A named entity", "kind" => "INTERFACE", "possibleTypes" => [%{"name" => "Person"}, %{"name" => "Business"}]}}}}, result
    end

  end

end
