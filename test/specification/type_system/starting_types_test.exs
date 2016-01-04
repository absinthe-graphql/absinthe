defmodule Specification.TypeSystem.StartingTypesTest do
  use ExSpec, async: true
  @moduletag specification: true, pending: true

  @graphql_spec "#sec-Starting-types"

  describe "the query type" do
    it "must be defined"
    it "must be an object base type"
  end

  describe "the mutation type" do
    it "is optional"
    describe "if provided" do
      it "must be an object base type"
    end
  end

end
