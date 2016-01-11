defmodule Absinthe.Specification.Introspection.Schema.ObjectTest do
  use ExSpec, async: true
  import AssertResult

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
          fields(include_deprecated: true) {
            name
            is_deprecated
            deprecation_reason
          }
        }
      }
      """
      |> Absinthe.run(ContactSchema)
      assert_result {:ok, %{data: %{"__type" => %{"kind" => "OBJECT",
                                                  "name" => "Person",
                                                  "description" => "A person",
                                                  "fields" => [%{"name" => "others", "is_deprecated" => false, "deprecation_reason" => nil},
                                                               %{"name" => "name", "is_deprecated" => false, "deprecation_reason" => nil},
                                                               %{"name" => "age", "is_deprecated" => false, "deprecation_reason" => nil},
                                                               %{"name" => "address", "is_deprecated" => true, "deprecation_reason" => "change of privacy policy"}]}}}}, result
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
