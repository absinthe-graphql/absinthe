defmodule Specification.TypeSystem.DirectivesTest do
  use ExSpec, async: true
  @moduletag specification: true

  @graphql_spec "#sec-Type-System.Directives"

  describe "the `@skip` directive" do
    @query_field """
    query Test($skipPerson: Boolean!) {
      person @skip(if: $skipPerson) {
        name
      }
    }
    """
    it "is defined" do
      assert ContactSchema.schema.directives[:skip]
    end
    it "behaves as expected for a field" do
      assert {:ok, %{data: %{"person" => %{"name" => "Bruce"}}}} == Absinthe.run(@query_field, ContactSchema, variables: %{"skipPerson" => false})
      assert {:ok, %{data: %{}}} == Absinthe.run(@query_field, ContactSchema, variables: %{"skipPerson" => true})
    end
  end

  describe "the `@include` directive" do
    it "is defined" do
      assert ContactSchema.schema.directives[:include]
    end
    @tag :pending
    it "behaves as expected"
  end

end
