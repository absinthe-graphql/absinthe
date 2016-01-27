defmodule Specification.TypeSystem.Types.UnionsTest do
  use ExSpec, async: true
  @moduletag specification: true

  @graphql_spec "#sec-Unions"

  describe "resolving __typename" do

    @query """
    {
      firstSearchResult {
        __typename
      }
    }
    """

    it "resolves correctly" do
      assert {:ok, %{data: %{"firstSearchResult" => %{"__typename" => "Person"}}}} = Absinthe.run(@query, ContactSchema)
    end

  end

  describe "resolving a concrete field without a fragment" do

    @query """
    {
      firstSearchResult {
        __typename
       name
      }
    }
    """

    it "does not resolve" do
      assert {:ok, %{errors: _}} = Absinthe.run(@query, ContactSchema)
    end

  end


  describe "resolving a concrete field with a fragment" do

    @query """
    {
      firstSearchResult {
        __typename
        ... on Person {
          name
        }
      }
    }
    """

    it "resolves" do
      assert {:ok, %{data: %{"firstSearchResult" => %{"__typename" => "Person", "name" => "Bruce"}}}} = Absinthe.run(@query, ContactSchema)
    end

  end

end
