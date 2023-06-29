defmodule Absinthe.Schema.Notation.Experimental.MacroExtensionsTest do
  use Absinthe.Case, async: true
  import ExperimentalNotationHelpers

  @moduletag :experimental
  @moduletag :sdl

  defmodule WithFeatureDirective do
    use Absinthe.Schema.Prototype

    input_object :related_feature do
      field :name, :string
    end

    directive :feature do
      arg :name, :string
      arg :related_features, list_of(:related_feature)
      on [:scalar, :schema]

      expand(fn _args, node ->
        %{node | __private__: [feature: true]}
      end)
    end
  end

  defmodule ExtendedSchema do
    use Absinthe.Schema

    @prototype_schema WithFeatureDirective

    query do
      field :foo, :string
    end

    extend schema do
      directive :feature, related_features: [%{"name" => "another_feature"}]
    end

    object :person do
      field :name, :string
    end

    object :photo do
      field :height, :integer
    end

    enum :direction do
      value :north
    end

    union :search_result do
      types [:photo]
    end

    scalar :my_custom_scalar, []

    interface :named_entity do
      field :name, :string
    end

    interface :valued_entity do
      field :value, :integer

      resolve_type fn
        _, _ -> :photo
      end
    end

    input_object :point do
      field :x, :float
    end

    extend enum(:direction) do
      value :south
    end

    extend enum(:direction) do
      value :west
    end

    extend union(:search_result) do
      types [:person]
    end

    extend scalar(:my_custom_scalar) do
      directive :feature
    end

    extend interface :named_entity do
      interface :valued_entity
      field :nickname, :string
      field :value, :integer
    end

    extend object(:photo) do
      interface :valued_entity
      field :width, :integer
      field :value, :integer
    end

    extend object(:query) do
      field :width, :integer
      field :value, :integer
    end

    extend input_object(:point) do
      field :y, :float
    end
  end

  test "can extend schema" do
    schema_declaration = ExtendedSchema.__absinthe_schema_declaration__()

    assert [%{name: "feature"}] = schema_declaration.directives
    assert [feature: true] == schema_declaration.__private__
  end

  test "can extend enums" do
    object = lookup_compiled_type(ExtendedSchema, :direction)

    assert %{
             north: %Absinthe.Type.Enum.Value{
               name: "NORTH",
               value: :north
             },
             south: %Absinthe.Type.Enum.Value{
               name: "SOUTH",
               value: :south
             },
             west: %Absinthe.Type.Enum.Value{
               name: "WEST",
               value: :west
             }
           } = object.values
  end

  test "can extend unions" do
    object = lookup_compiled_type(ExtendedSchema, :search_result)

    assert [:person, :photo] = object.types
  end

  test "can extend scalars" do
    object = lookup_compiled_type(ExtendedSchema, :my_custom_scalar)

    assert [{:feature, true}] = object.__private__
  end

  test "can extend objects" do
    object = lookup_compiled_type(ExtendedSchema, :photo)

    assert [
             %{
               name: "__typename",
               type: :string
             },
             %{
               name: "height",
               type: :integer
             },
             %{
               name: "value",
               type: :integer
             },
             %{
               name: "width",
               type: :integer
             }
           ] = Map.values(object.fields) |> Enum.sort_by(& &1.name)

    assert [:valued_entity] = object.interfaces
  end

  test "can extend root objects" do
    object = lookup_compiled_type(ExtendedSchema, :query)

    assert [
             %{
               name: "__schema",
               type: :__schema
             },
             %{
               name: "__type",
               type: :__type
             },
             %{
               name: "__typename",
               type: :string
             },
             %{
               name: "foo",
               type: :string
             },
             %{
               name: "value",
               type: :integer
             },
             %{
               name: "width",
               type: :integer
             }
           ] = Map.values(object.fields) |> Enum.sort_by(& &1.name)
  end

  test "can extend input objects" do
    object = lookup_compiled_type(ExtendedSchema, :point)

    assert [
             %{
               name: "x",
               type: :float
             },
             %{
               name: "y",
               type: :float
             }
           ] = Map.values(object.fields) |> Enum.sort_by(& &1.name)
  end

  test "can extend interfaces" do
    object = lookup_compiled_type(ExtendedSchema, :named_entity)

    assert [
             %{
               name: "__typename",
               type: :string
             },
             %{
               name: "name",
               type: :string
             },
             %{
               name: "nickname",
               type: :string
             },
             %{
               name: "value",
               type: :integer
             }
           ] = Map.values(object.fields) |> Enum.sort_by(& &1.name)

    assert [:valued_entity] = object.interfaces
  end

  test "can use map in arguments" do
    sdl = Absinthe.Schema.to_sdl(ExtendedSchema)

    assert sdl =~ "schema @feature(related_features: [{name: \"another_feature\"}])"
  end

  test "raises when definition types do not match" do
    schema = """
    defmodule KeywordExtend do
      use Absinthe.Schema

      query do
      end

      enum :direction do
        value :north
        value :east
      end

      extend union :direction do
        types [:west]
      end
    end
    """

    error = ~r/Type extension type does not match definition type for :direction./

    assert_raise(Absinthe.Schema.Error, error, fn ->
      Code.eval_string(schema)
    end)
  end

  test "raises when extend has unknown type" do
    schema = """
    defmodule UnknownTypeExtend do
      use Absinthe.Schema

      query do
      end

      extend enum :foo do
        value :south
      end
    end
    """

    error = ~r/In type extension the target type :foo is not\ndefined in your schema./

    assert_raise(Absinthe.Schema.Error, error, fn ->
      Code.eval_string(schema, [], __ENV__)
    end)
  end

  defmodule ImportedSchema do
    use Absinthe.Schema.Notation

    extend enum(:direction) do
      value :north
    end
  end

  defmodule ImportingSchema do
    use Absinthe.Schema

    query do
      field :foo, :string
    end

    import_type_extensions ImportedSchema

    enum :direction do
      value :south
    end
  end

  describe "import type extensions" do
    test "can extend enums" do
      object = lookup_compiled_type(ImportingSchema, :direction)

      assert %{
               north: %Absinthe.Type.Enum.Value{
                 name: "NORTH",
                 value: :north
               },
               south: %Absinthe.Type.Enum.Value{
                 name: "SOUTH",
                 value: :south
               }
             } = object.values
    end
  end
end
