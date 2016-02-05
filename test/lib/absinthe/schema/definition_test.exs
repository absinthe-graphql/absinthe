defmodule Absinthe.Schema.DefinitionTest do
  use ExSpec, async: true

  alias Absinthe.Schema
  alias Absinthe.Type

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
      assert %{person: "Person"} = ValidSchema.__absinthe_types__
    end

    it "includes the built-in types" do
      load_valid_schema
      assert map_size(Absinthe.Type.BuiltIns.__absinthe_types__) > 0
      Absinthe.Type.BuiltIns.__absinthe_types__
      |> Enum.each(fn
        {ident, name} ->
          assert ValidSchema.__absinthe_type__(ident) == ValidSchema.__absinthe_type__(name)
      end)
      int = ValidSchema.__absinthe_type__(:integer)
      assert 1 == Type.Scalar.serialize(int, 1)
      assert {:ok, 1} == Type.Scalar.parse(int, "1.0")
    end

  end

  describe "using the same identifier" do

    def load_duplicate_identifier_schema do
      load_schema("schema_with_duplicate_identifiers")
    end

    it "raises an exception" do
      err = assert_raise(Absinthe.Schema.Error, &load_duplicate_identifier_schema/0)
      assert [%{name: :dup_type_ident, location: _, data: :person}] = err.problems
    end

  end

  describe "using the same name" do

    def load_duplicate_name_schema do
      load_schema("schema_with_duplicate_names")
    end

    it "raises an exception" do
      err = assert_raise(Absinthe.Schema.Error, &load_duplicate_name_schema/0)
      assert [%{name: :dup_type_name, location: _, data: "Person"}] = err.problems
    end

  end

  defmodule SourceSchema do
    use Absinthe.Schema.Definition

    query [
      fields: [
        foo: [
          type: :foo,
          resolve: fn
            _, _ -> {:ok, %{name: "Fancy Foo!"}}
          end
        ]
      ]
    ]

    object :foo, [
      fields: [
        name: [type: :string]
      ]
    ]

  end

  defmodule UserSchema do
    use Absinthe.Schema.Definition

    import_types SourceSchema

    query [
      fields: [
        foo: [
          type: :foo,
          resolve: fn
            _, _ -> {:ok, %{name: "A different fancy Foo!"}}
          end
        ],
        bar: [
          type: :bar,
          resolve: fn
            _, _ -> {:ok, %{name: "A plain old bar"}}
          end
        ]
      ]
    ]

    object :bar, [
      fields: [
        name: [type: :string]
      ]
    ]

  end

  defmodule ThirdSchema do
    use Absinthe.Schema.Definition

    import_types UserSchema

    object :baz, [
      fields: [
        name: [type: :string]
      ]
    ]

  end


  describe "using import_types" do

    it "adds the types from a parent" do
      assert %{foo: "Foo", bar: "Bar"} = UserSchema.__absinthe_types__
      assert "Foo" == UserSchema.__absinthe_type__(:foo).name
    end

    it "adds the types from a grandparent" do
      assert %{foo: "Foo", bar: "Bar", baz: "Baz"} = ThirdSchema.__absinthe_types__
      assert "Foo" == ThirdSchema.__absinthe_type__(:foo).name
    end

  end

  describe "lookup_type" do

    it "is supported" do
      assert "Foo" == Schema.lookup_type(ThirdSchema, :foo).name
    end

  end

  defmodule RootsSchema do
    use Absinthe.Schema.Definition

    import_types SourceSchema

    query [
      fields: [
        name: [type: :string]
      ]
    ]

    mutation "MyRootMutation", [
      fields: [
        name: [type: :string]
      ]
    ]
  end


  describe "root fields" do

    it "can have a default name" do
      assert "RootQueryType" == Schema.lookup_type(RootsSchema, :query).name
    end

    it "can have a custom name" do
      assert "MyRootMutation" == Schema.lookup_type(RootsSchema, :mutation).name
    end

  end

  describe "directives" do

    @tag :direct
    it "are loaded as built-ins" do
      load_schema("valid_schema")
      assert %{skip: "skip", include: "include"} = ValidSchema.__absinthe_directives__
      assert ValidSchema.__absinthe_directive__(:skip)
      assert ValidSchema.__absinthe_directive__("skip") == ValidSchema.__absinthe_directive__(:skip)
      assert Schema.lookup_directive(ValidSchema, :skip) == ValidSchema.__absinthe_directive__(:skip)
      assert Schema.lookup_directive(ValidSchema, "skip") == ValidSchema.__absinthe_directive__(:skip)
    end

  end

end
