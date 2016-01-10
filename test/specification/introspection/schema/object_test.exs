defmodule Absinthe.Specification.Introspection.Schema.ObjectTest do
  use ExSpec, async: true
  import AssertResult

  describe "introspection of an object type" do

    it "can use __Type and ignore deprecated fields" do
      result = """
      {
        __Type(name: "Person") {
          kind
          name
          description
          fields {
            name
          }
        }
      }
      """
      |> Absinthe.run(ContactSchema)
      assert_result {:ok, %{data: %{"__Type" => %{"name" => "Person", "description" => "A person", "kind" => "OBJECT", "fields" => [%{"name" => "name"}, %{"name" => "age"}]}}}}, result
    end

    @tag :type
    it "can use __Type and include deprecated fields" do
      result = """
      {
        __Type(name: "Person") {
          kind
          name
          description
          fields(include_deprecated: true) {
            name
            type {
              kind
              name
              of_type
            }
          }
        }
      }
      """
      |> Absinthe.run(ContactSchema)
      assert_result {:ok, %{data: %{"__Type" => %{"name" => "Person", "description" => "A person", "kind" => "OBJECT", "fields" => [%{"name" => "others", "type" => %{"name" => nil, "kind" => "LIST"}}, %{"name" => "name", "type" => %{"name" => "String", "kind" => "SCALAR"}}, %{"name" => "age", "type" => %{"name" => "Int", "kind" => "SCALAR"}}, %{"name" => "address", "type" => %{"name" => "String", "kind" => "SCALAR"}}]}}}}, result
    end

    it "can use __Type to view interfaces" do
      result = """
      {
        __Type(name: "Person") {
          interfaces {
            name
          }
        }
      }
      """
      |> Absinthe.run(ContactSchema)
      assert_result {:ok, %{data: %{"__Type" => %{"interfaces" => [%{"name" => "NamedEntity"}]}}}}, result
    end

  end

end
