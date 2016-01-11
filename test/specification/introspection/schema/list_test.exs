defmodule Absinthe.Specification.Introspection.Schema.ListTest do
  use ExSpec, async: true
  import AssertResult

  describe "introspection of an object type that includes a list" do

    it "can use __Type and see fields with the wrapping list types" do
      result = """
      {
        __Type(name: "Person") {
          fields(include_deprecated: true) {
            name
            type {
              kind
              name
              of_type {
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
                       %{"__Type" => %{
                          "fields" => [%{"name" => "others",
                                         "type" => %{"kind" => "LIST", "name" => nil,
                                                     "of_type" => %{"kind" => "OBJECT", "name" => "Person"}}},
                                       %{"name" => "name",
                                         "type" => %{"kind" => "SCALAR", "name" => "String", "of_type" => nil}},
                                       %{"name" => "age",
                                         "type" => %{"kind" => "SCALAR", "name" => "Int", "of_type" => nil}},
                                       %{"name" => "address",
                                         "type" => %{"kind" => "SCALAR", "name" => "String", "of_type" => nil}}]}}}}, result
    end

  end

end
