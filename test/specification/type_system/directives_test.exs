defmodule Specification.TypeSystem.DirectivesTest do
  use ExSpec, async: true
  @moduletag specification: true

  @graphql_spec "#sec-Type-System.Directives"

  describe "the `@skip` directive" do
    it "is defined" do
      assert ContactSchema.schema.directives[:skip]
    end
    @tag :pending
    it "behaves as expected"
  end

  describe "the `@include` directive" do
    it "is defined" do
      assert ContactSchema.schema.directives[:include]
    end
    @tag :pending
    it "behaves as expected"
  end

end
