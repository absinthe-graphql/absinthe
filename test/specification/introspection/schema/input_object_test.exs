defmodule Absinthe.Specification.Introspection.Schema.InputObjectTest do
  use ExSpec, async: true
  import AssertResult

  describe "introspection of an input object type" do

    it "can use __type and ignore deprecated fields" do
      result = """
      {
        __type(name: "ProfileInput") {
          kind
          name
          description
          input_fields {
            name
            description
            type {
              kind
              name
              of_type {
                kind
                name
              }
            }
            default_value
          }
        }
      }
      """
      |> Absinthe.run(ContactSchema)
      assert_result {:ok, %{data: %{"__type" => %{"name" => "ProfileInput", "description" => "The basic details for a person", "kind" => "INPUT_OBJECT", "input_fields" => [%{"name" => "name", "description" => "The person's name", "type" => %{"name" => "String", "kind" => "SCALAR", "of_type" => nil}, "default_value" => "Janet"}, %{"default_value" => nil, "description" => nil, "name" => "code", "type" => %{"kind" => "NON_NULL", "name" => nil, "of_type" => %{"kind" => "SCALAR", "name" => "String"}}}, %{"name" => "age", "description" => "The person's age", "type" => %{"name" => "Int", "kind" => "SCALAR", "of_type" => nil}, "default_value" => "43"}]}}}}, result
    end

  end

end
