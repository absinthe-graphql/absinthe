defmodule Absinthe.SchemaTest do
  use Absinthe.Case, async: true

  alias Absinthe.Schema
  alias Absinthe.Type

  describe "built-in types" do
    def load_valid_schema do
      load_schema("valid_schema")
    end

    test "are loaded" do
      load_valid_schema()
      assert map_size(Absinthe.Type.BuiltIns.__absinthe_types__()) > 0

      Absinthe.Type.BuiltIns.__absinthe_types__()
      |> Enum.each(fn {ident, name} ->
        assert Absinthe.Fixtures.ValidSchema.__absinthe_type__(ident) ==
                 Absinthe.Fixtures.ValidSchema.__absinthe_type__(name)
      end)

      int = Absinthe.Fixtures.ValidSchema.__absinthe_type__(:integer)
      assert 1 == Type.Scalar.serialize(int, 1)
      assert {:ok, 1} == Type.Scalar.parse(int, 1, %{})
    end
  end

  describe "using the same identifier" do
    test "raises an exception" do
      assert_schema_error("schema_with_duplicate_identifiers", [
        %{
          rule: Absinthe.Schema.Rule.TypeNamesAreUnique,
          data: %{artifact: "Absinthe type identifier", value: :person}
        }
      ])
    end
  end

  describe "using the same name" do
    def load_duplicate_name_schema do
      load_schema("schema_with_duplicate_names")
    end

    test "raises an exception" do
      assert_schema_error("schema_with_duplicate_names", [
        %{
          rule: Absinthe.Schema.Rule.TypeNamesAreUnique,
          data: %{artifact: "Type name", value: "Person"}
        }
      ])
    end
  end

  defmodule SourceSchema do
    use Absinthe.Schema

    @desc "can describe query"
    query do
      field :foo,
        type: :foo,
        resolve: fn _, _ -> {:ok, %{name: "Fancy Foo!"}} end
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
        resolve: fn _, _ -> {:ok, %{name: "A different fancy Foo!"}} end

      field :bar,
        type: :bar,
        resolve: fn _, _ -> {:ok, %{name: "A plain old bar"}} end
    end

    object :bar do
      field :name, :string
    end
  end

  defmodule ThirdSchema do
    use Absinthe.Schema

    interface :named do
      field :name, :string
      resolve_type fn _, _ -> nil end
    end

    interface :aged do
      field :age, :integer
      resolve_type fn _, _ -> nil end
    end

    union :pet do
      types [:dog]
    end

    object :dog do
      field :name, :string
    end

    enum :some_enum do
      values([:a, :b])
    end

    interface :loop do
      field :loop, :loop
    end

    directive :directive do
      arg :baz, :dir_enum
    end

    enum :dir_enum do
      value :foo
    end

    query do
      field :loop, :loop
      field :enum_field, :some_enum
      field :object_field, :user
      field :interface_field, :aged
      field :union_field, :pet
    end

    object :person do
      field :age, :integer
      interface :aged
    end

    import_types UserSchema

    object :user do
      field :name, :string
      interface :named
    end

    object :baz do
      field :name, :string
    end
  end

  test "can have a description on the root query" do
    assert "can describe query" == Absinthe.Schema.lookup_type(SourceSchema, :query).description
  end

  describe "using import_types" do
    test "adds the types from a parent" do
      assert %{foo: "Foo", bar: "Bar"} = UserSchema.__absinthe_types__()
      assert "Foo" == UserSchema.__absinthe_type__(:foo).name
    end

    test "adds the types from a grandparent" do
      assert %{foo: "Foo", bar: "Bar", baz: "Baz"} = ThirdSchema.__absinthe_types__()
      assert "Foo" == ThirdSchema.__absinthe_type__(:foo).name
    end
  end

  describe "lookup_type" do
    test "is supported" do
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

    subscription name: "RootSubscriptionTypeThing" do
      field :name, :string
    end
  end

  describe "used_types" do
    test "does not contain introspection types" do
      assert !Enum.any?(
               Schema.used_types(ThirdSchema),
               &Type.introspection?/1
             )
    end

    test "contains enums" do
      types =
        ThirdSchema
        |> Absinthe.Schema.used_types()
        |> Enum.map(& &1.identifier)

      assert :some_enum in types
      assert :dir_enum in types
    end

    test "contains interfaces" do
      types =
        ThirdSchema
        |> Absinthe.Schema.used_types()
        |> Enum.map(& &1.identifier)

      assert :named in types
    end

    test "contains types only connected via interfaces" do
      types =
        ThirdSchema
        |> Absinthe.Schema.used_types()
        |> Enum.map(& &1.identifier)

      assert :person in types
    end

    test "contains types only connected via union" do
      types =
        ThirdSchema
        |> Absinthe.Schema.used_types()
        |> Enum.map(& &1.identifier)

      assert :dog in types
    end
  end

  describe "introspection_types" do
    test "is not empty" do
      assert !Enum.empty?(Schema.introspection_types(ThirdSchema))
    end

    test "are introspection types" do
      assert Enum.all?(
               Schema.introspection_types(ThirdSchema),
               &Type.introspection?/1
             )
    end
  end

  describe "root fields" do
    test "can have a default name" do
      assert "RootQueryType" == Schema.lookup_type(RootsSchema, :query).name
    end

    test "can have a custom name" do
      assert "MyRootMutation" == Schema.lookup_type(RootsSchema, :mutation).name
    end

    test "supports subscriptions" do
      assert "RootSubscriptionTypeThing" == Schema.lookup_type(RootsSchema, :subscription).name
    end
  end

  describe "fields" do
    test "have the correct structure in query" do
      assert %Type.Field{name: "name"} = Schema.lookup_type(RootsSchema, :query).fields.name
    end

    test "have the correct structure in subscription" do
      assert %Type.Field{name: "name"} =
               Schema.lookup_type(RootsSchema, :subscription).fields.name
    end
  end

  describe "arguments" do
    test "have the correct structure" do
      assert %Type.Argument{name: "family_name"} =
               Schema.lookup_type(RootsSchema, :query).fields.name.args.family_name
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
    test "builds the correct result" do
      assert_result(
        {:ok, %{data: %{"viewer" => %{"id" => "ABCD", "name" => "Bruce"}}}},
        run(@query, FragmentSpreadSchema)
      )
    end
  end

  defmodule MetadataSchema do
    use Absinthe.Schema

    query do
      # Query type must exist
    end

    object :foo, meta: [foo: "bar"] do
      meta :sql_table, "foos"
      meta cache: false, eager: true

      field :bar, :string do
        meta :nice, "yup"
      end
    end

    input_object :input_foo do
      meta :is_input, true

      field :bar, :string do
        meta :nice, "nope"
      end
    end

    enum :color do
      meta :rgb_only, true
      value :red
      value :blue
      value :green
    end

    scalar :my_scalar do
      meta :is_scalar, true
      # Missing parse and serialize
    end

    interface :named do
      meta :is_interface, true

      field :name, :string do
        meta :is_name, true
      end
    end

    union :result do
      types [:foo]
      meta :is_union, true
    end
  end

  describe "can add metadata to an object" do
    @tag :wip
    test "sets object metadata" do
      foo = Schema.lookup_type(MetadataSchema, :foo)
      assert [eager: true, cache: false, sql_table: "foos", foo: "bar"] == foo.__private__[:meta]
      assert Type.meta(foo, :sql_table) == "foos"
      assert Type.meta(foo, :cache) == false
      assert Type.meta(foo, :eager) == true
    end

    test "sets field metadata" do
      foo = Schema.lookup_type(MetadataSchema, :foo)
      assert %{__private__: [meta: [nice: "yup"]]} = foo.fields[:bar]
      assert Type.meta(foo.fields[:bar], :nice) == "yup"
    end

    test "sets input object metadata" do
      input_foo = Schema.lookup_type(MetadataSchema, :input_foo)
      assert %{__private__: [meta: [is_input: true]]} = input_foo
      assert Type.meta(input_foo, :is_input) == true
    end

    test "sets input object field metadata" do
      input_foo = Schema.lookup_type(MetadataSchema, :input_foo)
      assert %{__private__: [meta: [nice: "nope"]]} = input_foo.fields[:bar]
      assert Type.meta(input_foo.fields[:bar], :nice) == "nope"
    end

    test "sets enum metadata" do
      color = Schema.lookup_type(MetadataSchema, :color)
      assert %{__private__: [meta: [rgb_only: true]]} = color
      assert Type.meta(color, :rgb_only) == true
    end

    test "sets scalar metadata" do
      my_scalar = Schema.lookup_type(MetadataSchema, :my_scalar)
      assert %{__private__: [meta: [is_scalar: true]]} = my_scalar
      assert Type.meta(my_scalar, :is_scalar) == true
    end

    test "sets interface metadata" do
      named = Schema.lookup_type(MetadataSchema, :named)
      assert %{__private__: [meta: [is_interface: true]]} = named
      assert Type.meta(named, :is_interface) == true
    end

    test "sets interface field metadata" do
      named = Schema.lookup_type(MetadataSchema, :named)
      assert %{__private__: [meta: [is_name: true]]} = named.fields[:name]
      assert Type.meta(named.fields[:name], :is_name) == true
    end

    test "sets union metadata" do
      result = Schema.lookup_type(MetadataSchema, :result)
      assert %{__private__: [meta: [is_union: true]]} = result
      assert Type.meta(result, :is_union) == true
    end
  end
end
