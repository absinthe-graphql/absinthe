defmodule Absinthe.SchemaTest do
  use Absinthe.Case, async: true
  use SupportSchemas

  alias Absinthe.Schema
  alias Absinthe.Type

  describe "built-in types" do

    def load_valid_schema do
      load_schema("valid_schema")
    end

    it "are loaded" do
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

    it "raises an exception" do
      assert_schema_error("schema_with_duplicate_identifiers",
                          [%{rule: Absinthe.Schema.Rule.TypeNamesAreUnique, data: %{artifact: "Absinthe type identifier", value: :person}}])
    end

  end

  describe "using the same name" do

    def load_duplicate_name_schema do
      load_schema("schema_with_duplicate_names")
    end

    it "raises an exception" do
      assert_schema_error("schema_with_duplicate_names",
                          [%{rule: Absinthe.Schema.Rule.TypeNamesAreUnique, data: %{artifact: "Type name", value: "Person"}}])
    end

  end

  defmodule SourceSchema do
    use Absinthe.Schema

    query do
      field :foo,
        type: :foo,
        resolve: fn
          _, _ -> {:ok, %{name: "Fancy Foo!"}}
        end
    end

    object :foo do
      field :name, :string
    end

  end

  defmodule UserSchema do
    use Absinthe.Schema

    import_types SourceSchema

    query do
      field :foo,
        type: :foo,
        resolve: fn
          _, _ -> {:ok, %{name: "A different fancy Foo!"}}
        end

      field :bar,
        type: :bar,
        resolve: fn
          _, _ -> {:ok, %{name: "A plain old bar"}}
        end

    end

    object :bar do
      field :name, :string
    end

  end

  defmodule ThirdSchema do
    use Absinthe.Schema

    import_types UserSchema

    object :baz do
      field :name, :string
    end

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
    use Absinthe.Schema

    import_types SourceSchema

    query do

      field :name,
        type: :string,
        args: [
          family_name: [type: :boolean]
        ]

    end

    mutation name: "MyRootMutation" do
      field :name, :string
    end

    subscription name: "SubscriptionRootTypeThing" do
      field :name, :string
    end

  end


  describe "root fields" do

    it "can have a default name" do
      assert "RootQueryType" == Schema.lookup_type(RootsSchema, :query).name
    end

    it "can have a custom name" do
      assert "MyRootMutation" == Schema.lookup_type(RootsSchema, :mutation).name
    end

    it "supports subscriptions" do
      assert "SubscriptionRootTypeThing" == Schema.lookup_type(RootsSchema, :subscription).name
    end


  end

  describe "fields" do

    it "have the correct structure in query" do
      assert %Type.Field{name: "name"} = Schema.lookup_type(RootsSchema, :query).fields.name
    end

    it "have the correct structure in subscription" do
      assert %Type.Field{name: "name"} = Schema.lookup_type(RootsSchema, :subscription).fields.name
    end

  end

  describe "arguments" do

    it "have the correct structure" do
      assert %Type.Argument{name: "family_name"} = Schema.lookup_type(RootsSchema, :query).fields.name.args.family_name
    end

  end

  defmodule FragmentSpreadSchema do
    use Absinthe.Schema

    @viewer %{id: "ABCD", name: "Bruce"}

    query do
      field :viewer, :viewer do
        resolve fn _, _ -> {:ok, @viewer} end
      end
    end

    object :viewer do
      field :id, :id
      field :name, :string
    end

  end

  describe "multiple fragment spreads" do

    @query """
    query Viewer{viewer{id,...F1}}
    fragment F0 on Viewer{name,id}
    fragment F1 on Viewer{id,...F0}
    """

    @tag :fragment1
    it "builds the correct result" do
      assert {:ok, %{data: %{"viewer" => %{"id" => "ABCD", "name" => "Bruce"}}}} == Absinthe.run(@query, FragmentSpreadSchema)
    end

  end

end
