defmodule Specification.TypeSystem.Types.EnumsTest do
  use ExSpec, async: true
  use SpecificationVerification

  @graphql_spec "#sec-Enums"

  describe "enum" do

    describe "result coercion" do
      it "must return one of the defined set of possible values"
      describe "if a reasonable coercion is not possible" do
        it "must raise a field error"
      end
    end

    describe "input coercion" do
      describe "when a string literal is provided" do
        it "must not be accepted and instead raise a query error"
      end
    end

  end

end
