defmodule Absinthe.Specification.Introspection.Type.InputObjectTest do
  use ExSpec, async: true
  import AssertResult

  @moduletag :specification

  describe "introspection of an input object type" do

    it "can use __type and ignore deprecated fields" do
      result = """
      {
        __type(name: "ProfileInput") {
          kind
          name
          description
          inputFields {
            name
            description
            type {
              kind
              name
              ofType {
                kind
                name
              }
            }
            defaultValue
          }
        }
      }
      """
      |> Absinthe.run(ContactSchema)
      assert_result {:ok, %{data: %{"__type" => %{"name" => "ProfileInput", "description" => "The basic details for a person", "kind" => "INPUT_OBJECT", "inputFields" => [%{"name" => "name", "description" => "The person's name", "type" => %{"name" => "String", "kind" => "SCALAR", "ofType" => nil}, "defaultValue" => "Janet"}, %{"defaultValue" => nil, "description" => nil, "name" => "code", "type" => %{"kind" => "NON_NULL", "name" => nil, "ofType" => %{"kind" => "SCALAR", "name" => "String"}}}, %{"name" => "age", "description" => "The person's age", "type" => %{"name" => "Int", "kind" => "SCALAR", "ofType" => nil}, "defaultValue" => "43"}]}}}}, result
    end

  end

end
