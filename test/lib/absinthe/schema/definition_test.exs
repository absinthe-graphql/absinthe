defmodule Absinthe.Schema.DefinitionTest do
  use ExSpec, async: true

  def load_schema(name) do
    Code.require_file("test/support/lib/absinthe/schema/#{name}.exs")
  end

  describe "object" do

    def load_valid_schema do
      load_schema("valid_schema")
    end

    it "defines an object" do
      load_valid_schema
      obj = ValidSchema.__absinthe_type__(:person)
      assert obj.name == "Person"
      assert obj.description == "A person"
      assert %{person: "Person"} == ValidSchema.__absinthe_types__
    end

  end

  describe "using the same identifier" do

    def load_duplicate_identifier_schema do
      load_schema("schema_with_duplicate_identifiers")
    end

    it "raises an exception" do
      err = assert_raise(Absinthe.Schema.Error, &load_duplicate_identifier_schema/0)
      assert [%{name: :dup_ident, location: _, data: :person}] = err.problems
    end

  end

  describe "using the same name" do

    def load_duplicate_name_schema do
      load_schema("schema_with_duplicate_names")
    end

    it "raises an exception" do
      err = assert_raise(Absinthe.Schema.Error, &load_duplicate_name_schema/0)
      assert [%{name: :dup_name, location: _, data: "Person"}] = err.problems
    end

  end

end
