defmodule Absinthe.Schema.DefinitionTest do
  use ExSpec, async: true

  defmodule Schema do
    use Absinthe.Schema.Definition

    @doc "A person"
    object :person, [
      fields: [
        name: [type: :string]
      ]
    ]

  end


  describe "object" do

    it "defines an object" do
      obj = Schema.__absinthe_type__(:person)
      assert obj.name == "Person"
      assert obj.description == "A person"
      assert %{person: "Person"} == Schema.__absinthe_types__
    end

  end

  defmodule SchemaWithDuplicateIdentifiers do
    use Absinthe.Schema.Definition

    @doc "A person"
    object :person, [
      fields: [
        name: [type: :string]
      ]
    ]

    @doc "A person"
    object [person: "APersonToo]"], [
      fields: [
        name: [type: :string]
      ]
    ]
  end

  describe "using the same identifier" do

    it "adds an error" do
      assert [%{error: :type_identifier_already_defined, location: _, data: :person}] = SchemaWithDuplicateIdentifiers.__absinthe_errors__
    end

  end

  defmodule SchemaWithDuplicateNames do
    use Absinthe.Schema.Definition

    @doc "A person"
    object :person, [
      fields: [
        name: [type: :string]
      ]
    ]

    @doc "A person"
    object [another_person: "Person"], [
      fields: [
        name: [type: :string]
      ]
    ]
  end

  describe "using the same name" do

    it "registers an error" do
      assert [%{error: :type_name_already_defined, location: _, data: "Person"}] = SchemaWithDuplicateNames.__absinthe_errors__
    end

  end


end
