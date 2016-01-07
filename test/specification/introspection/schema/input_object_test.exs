defmodule Absinthe.Specification.Introspection.Schema.InputObjectTest do
  use ExSpec, async: true
  import AssertResult

  describe "introspection of an input object type" do

    it "can use __Type and ignore deprecated fields" do
      result = """
      {
        __Type(name: "ProfileInput") {
          kind
          name
          description
          input_fields {
            name
            description
            type {
              name
            }
            default_value
          }
        }
      }
      """
      |> Absinthe.run(ContactSchema)
      assert_result {:ok, %{data: %{"__Type" => %{"name" => "ProfileInput", "description" => "The basic details for a person", "kind" => "INPUT_OBJECT", "input_fields" => [%{"name" => "name", "description" => "The person's name", "type" => %{"name" => "String"}, "default_value" => "Janet"}, %{"name" => "age", "description" => "The person's age", "type" => %{"name" => "Int"}, "default_value" => "43"}]}}}}, result
    end

  end

end
