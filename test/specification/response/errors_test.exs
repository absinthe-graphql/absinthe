defmodule Specification.Response.ErrorsTest do
  use ExSpec, async: true
  use SpecificationVerification

  @graphql_spec "#sec-Errors"

  describe "the errors entry in the response" do

    describe "if no errors were encountered during the requested operation" do
      it "should not be present"
    end

    describe "if errors were encountered during the requested operation" do
      it "should be a non-empty list"
      it "must contain an entry with the key message"
      it "can be associated to a particular point with the key locations, where each location is a map with the keys line and column"
      describe "the error locations" do
        it "should have a positive line number, starting with 1"
        # XXX: Not supported by Leex, the tokenizer. We return 0 for the time being.
        @tag :pending
        it "should have a positive column number, starting with 1"
      end
    end

    describe "if an error occurs before execution begins" do
      it "should not be present"
    end

    describe "if an error occurs that prevented a valid response" do
      it "should be null"
    end

    describe "if the data entry is null or not present" do
      it "must not be empty"
      it "must contain at least one error"
      it "should indicate why no data was able to be returned"
    end

    describe "if the data entry is not null" do
      it "may contain any errors that occurred during execution"
    end

  end

  describe "graphql servers" do
    # TODO: We have several enhancements planned (level, path, etc)
    @tag :pending
    it "may provide additional entries to error as the choose to produce more helpful or machine-readable errors"
  end

end
