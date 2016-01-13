defmodule Absinthe.Specification.Introspection.Type.EnumTest do
  use ExSpec, async: true

  @moduletag :specification

  describe "introspection of an enum type" do

    it "can use __type and value information with deprecations" do
      result = """
      {
        __type(name: "Channel") {
          kind
          name
          description
          enumValues(includeDeprecated: true) {
            name
            description
            isDeprecated
            deprecationReason
          }
        }
      }
      """
      |> Absinthe.run(ColorSchema)
      assert {:ok, %{data: %{"__type" => %{"name" => "Channel", "description" => "A color channel", "kind" => "ENUM", "enumValues" => values}}}} = result
      assert [
        %{"name" => "blue", "description" => "The color blue", "isDeprecated" => false, "deprecationReason" => nil},
        %{"name" => "green", "description" => "The color green", "isDeprecated" => false, "deprecationReason" => nil},
        %{"name" => "puce", "description" => "The color puce", "isDeprecated" => true, "deprecationReason" => "it's ugly"},
        %{"name" => "red", "description" => "The color red", "isDeprecated" => false, "deprecationReason" => nil}
      ] == values |> Enum.sort_by(&(&1["name"]))
    end

    it "can use __type and value information without deprecations" do
      result = """
      {
        __type(name: "Channel") {
          kind
          name
          description
          enumValues {
            name
            description
          }
        }
      }
      """
      |> Absinthe.run(ColorSchema)
      assert {:ok, %{data: %{"__type" => %{"name" => "Channel", "description" => "A color channel", "kind" => "ENUM", "enumValues" => values}}}} = result
      assert [
        %{"name" => "blue", "description" => "The color blue"},
        %{"name" => "green", "description" => "The color green"},
        %{"name" => "red", "description" => "The color red"}
      ] == values |> Enum.sort_by(&(&1["name"]))
    end

  end

end
