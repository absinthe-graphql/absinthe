defmodule Specification.Response.DataTest do
  use ExSpec, async: true
  @moduletag specification: true, pending: true

  @graphql_spec "#sec-Data"

  describe "the data entry in the response" do

    describe "if the operation was a query" do

      it "will be an object of the schema's query root type"
    end

    describe "if the operation was a mutation" do
      @tag :specification
      it "will be an object of the schema's mutation root type"
    end

    describe "if an error occurs before execution begins" do
      @tag :specification
      it "should not be present"
    end

    describe "if an error occurs that prevented a valid response" do
      @tag :specification
      it "should be null"
    end

  end

end
