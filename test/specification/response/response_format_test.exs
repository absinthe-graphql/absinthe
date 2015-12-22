defmodule Specification.Response.ResponseFormatTest do
  use ExSpec, async: true
  use SpecificationVerification

  @graphql_spec "#sec-Response-Format"

  describe "a response" do

    it "must be a map"

    describe "if the operation included execution" do

      it "must contain an entry with key `data`"

      describe "if the operation failed before execution due to a syntax error, missing information, or validation error" do
        it "must not be present"
      end

      describe "if the operation encountered any errors" do
        it "must contain an entry with the key `errors`"
      end

      describe "if the operation completed without encountering any errors" do
        it "must not be present"
      end

    end

    it "must not contain any top level entries other than `data`, `errors`, and `extensions`"

  end

  describe "graphql servers" do
    # TODO: For any enhancements
    @tag :pending
    it "may extend the protocol by using the `extensions` key in the response"
  end

end
