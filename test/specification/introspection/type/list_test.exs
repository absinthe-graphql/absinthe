defmodule Absinthe.Specification.Introspection.Type.ListTest do
  use ExSpec, async: true
  import AssertResult

  @moduletag :specification

  describe "introspection of an object type that includes a list" do

    it "can use __type and see fields with the wrapping list types" do
      result = """
      {
        __type(name: "Person") {
          fields(include_deprecated: true) {
            name
            type {
              kind
              name
              ofType {
                kind
                name
              }
            }
          }
        }
      }
      """
      |> Absinthe.run(ContactSchema)
      assert_result {:ok,
                     %{data:
                       %{"__type" => %{
                          "fields" => [%{"name" => "others",
                                         "type" => %{"kind" => "LIST", "name" => nil,
                                                     "ofType" => %{"kind" => "OBJECT", "name" => "Person"}}},
                                       %{"name" => "name",
                                         "type" => %{"kind" => "SCALAR", "name" => "String", "ofType" => nil}},
                                       %{"name" => "age",
                                         "type" => %{"kind" => "SCALAR", "name" => "Int", "ofType" => nil}},
                                       %{"name" => "address",
                                         "type" => %{"kind" => "SCALAR", "name" => "String", "ofType" => nil}}]}}}}, result
    end

  end

end
