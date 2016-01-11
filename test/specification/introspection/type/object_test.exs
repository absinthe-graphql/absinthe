defmodule Absinthe.Specification.Introspection.Type.ObjectTest do
  use ExSpec, async: true
  import AssertResult

  @moduletag :specification

  describe "introspection of an object type" do

    it "can use __type and ignore deprecated fields" do
      result = """
      {
        __type(name: "Person") {
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
      assert_result {:ok, %{data: %{"__type" => %{"name" => "Person", "description" => "A person", "kind" => "OBJECT", "fields" => [%{"name" => "others"}, %{"name" => "name"}, %{"name" => "age"}]}}}}, result
    end

    it "can use __type and include deprecated fields" do
      result = """
      {
        __type(name: "Person") {
          kind
          name
          description
          fields(includeDeprecated: true) {
            name
            isDeprecated
            deprecationReason
          }
        }
      }
      """
      |> Absinthe.run(ContactSchema)
      assert_result {:ok, %{data: %{"__type" => %{"kind" => "OBJECT",
                                                  "name" => "Person",
                                                  "description" => "A person",
                                                  "fields" => [%{"name" => "others", "isDeprecated" => false, "deprecationReason" => nil},
                                                               %{"name" => "name", "isDeprecated" => false, "deprecationReason" => nil},
                                                               %{"name" => "age", "isDeprecated" => false, "deprecationReason" => nil},
                                                               %{"name" => "address", "isDeprecated" => true, "deprecationReason" => "change of privacy policy"}]}}}}, result
    end

    it "can use __type to view interfaces" do
      result = """
      {
        __type(name: "Person") {
          interfaces {
            name
          }
        }
      }
      """
      |> Absinthe.run(ContactSchema)
      assert_result {:ok, %{data: %{"__type" => %{"interfaces" => [%{"name" => "NamedEntity"}]}}}}, result
    end

  end

end
