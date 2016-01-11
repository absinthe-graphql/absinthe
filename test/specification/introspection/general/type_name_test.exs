defmodule Absinthe.Specification.Introspection.General.TypeNameTest do
  use ExSpec, async: true
  import AssertResult

  describe "when querying against an object" do
    it "returns the name of the object type currently being queried" do
      # Without an alias
      result = "{ person { __typename name } }" |> Absinthe.run(ContactSchema)
      assert_result {:ok, %{data: %{"person" => %{"name" => "Bruce", "__typename" => "Person"}}}}, result
      # With an alias
      result = "{ person { kind: __typename name } }" |> Absinthe.run(ContactSchema)
      assert_result {:ok, %{data: %{"person" => %{"name" => "Bruce", "kind" => "Person"}}}}, result
    end
  end

  describe "when querying against an interface" do
    it "returns the name of the object type currently being queried" do
      # Without an alias
      result = "{ contact { entity { __typename name } } }" |> Absinthe.run(ContactSchema)
      assert_result {:ok, %{data: %{"contact" => %{"entity" => %{"name" => "Bruce", "__typename" => "Person"}}}}}, result
      # With an alias
      result = "{ contact { entity { kind: __typename name } } }" |> Absinthe.run(ContactSchema)
      assert_result {:ok, %{data: %{"contact" => %{"entity" => %{"name" => "Bruce", "kind" => "Person"}}}}}, result
    end
  end

  describe "when querying against a union" do
    it "returns the name of the object type currently being queried" do
    end
  end


end
