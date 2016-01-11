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
      assert_result {:ok, %{data: %{"__Type" => %{"name" => "Person", "description" => "A person", "kind" => "OBJECT", "fields" => [%{"name" => "others"}, %{"name" => "name"}, %{"name" => "age"}]}}}}, result
    end

    it "can use __Type and include deprecated fields" do
      result = """
      {
        __Type(name: "Person") {
          kind
          name
          description
          fields(include_deprecated: true) {
            name
            is_deprecated
            deprecation_reason
          }
        }
      }
      """
      |> Absinthe.run(ContactSchema)
      assert_result {:ok, %{data: %{"__Type" => %{"kind" => "OBJECT",
                                                  "name" => "Person",
                                                  "description" => "A person",
                                                  "fields" => [%{"name" => "others", "is_deprecated" => false, "deprecation_reason" => nil},
                                                               %{"name" => "name", "is_deprecated" => false, "deprecation_reason" => nil},
                                                               %{"name" => "age", "is_deprecated" => false, "deprecation_reason" => nil},
                                                               %{"name" => "address", "is_deprecated" => true, "deprecation_reason" => "change of privacy policy"}]}}}}, result
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
