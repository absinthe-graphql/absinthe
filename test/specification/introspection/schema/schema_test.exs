defmodule Absinthe.Specification.Introspection.Schema.SchemaTest do
  use ExSpec, async: true
  import AssertResult

  @moduletag :specification

  describe "introspection of a schema" do

    it "can use __schema to get types" do
      {:ok, %{data: %{"__schema" => %{"types" => types}}}} = Absinthe.run(
        "{ __schema { types { name } } }",
        ContactSchema
      )
      names = types |> Enum.map(&(&1["name"])) |> Enum.sort
      expected = ~w(Int ID String Boolean Float Contact Person Business ProfileInput SearchResult NamedEntity RootMutationType RootQueryType __Directive __EnumValue __Field __InputValue __Type) |> Enum.sort
      assert expected == names
    end

    it "can use __schema to get the query type" do
      result = "{ __schema { queryType { name kind } } }" |> Absinthe.run(ContactSchema)
      assert_result {:ok, %{data: %{"__schema" => %{"queryType" => %{"name" => "RootQueryType", "kind" => "OBJECT"}}}}}, result
    end

    it "can use __schema to get the mutation type" do
      result = "{ __schema { mutationType { name kind } } }" |> Absinthe.run(ContactSchema)
      assert_result {:ok, %{data: %{"__schema" => %{"mutationType" => %{"name" => "RootMutationType", "kind" => "OBJECT"}}}}}, result
    end

    it "can use __schema to get the directives" do
      result = "{ __schema { directives { name args { name type { kind ofType { name kind } } } onOperation onFragment onField } } }" |> Absinthe.run(ContactSchema)
      assert {:ok, %{data: %{"__schema" => %{"directives" => [
                                              %{"name" => "skip", "args" => [%{"name" => "if", "type" => %{"kind" => "NON_NULL", "ofType" => %{"name" => "Boolean", "kind" => "SCALAR"}}}], "onOperation" => false, "onFragment" => true, "onField" => true},
                                              %{"name" => "include", "args" => [%{"name" => "if", "type" => %{"kind" => "NON_NULL", "ofType" => %{"name" => "Boolean", "kind" => "SCALAR"}}}], "onOperation" => false, "onFragment" => true, "onField" => true}
                                            ]}}}} == result
    end

  end

end
