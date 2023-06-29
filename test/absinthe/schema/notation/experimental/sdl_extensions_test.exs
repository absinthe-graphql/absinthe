defmodule Absinthe.Schema.Notation.Experimental.SdlExtensionsTest do
  use Absinthe.Case, async: true
  import ExperimentalNotationHelpers

  @moduletag :experimental
  @moduletag :sdl

  defmodule WithFeatureDirective do
    use Absinthe.Schema.Prototype

    directive :feature do
      arg :name, :string
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

    import_sdl """
    type Person {
      name: String
    }

    type Photo {
      height: Int
      width: Int
    }

    type MyMutationRootType {
      name: String
    }

    enum Direction {
      NORTH
    }

    input Point {
      x: Float
    }

    union SearchResult = Photo

    scalar MyCustomScalar

    interface NamedEntity {
      name: String
    }

    interface ValuedEntity {
      value: Int
    }

    extend schema @feature {
      mutation: MyMutationRootType
    }

    extend enum Direction {
      SOUTH
    }

    extend enum Direction {
      WEST
    }

    extend union SearchResult = Person

    extend scalar MyCustomScalar @feature

    extend type Photo implements ValuedEntity {
      value: Int
    }

    extend interface NamedEntity implements ValuedEntity {
      nickname: String
      value: Int
    }

    extend input Point {
      y: Float
    }
    """

    def hydrate(%{identifier: :valued_entity}, _) do
      [{:resolve_type, &__MODULE__.valued_entity_resolve_type/2}]
    end

    def hydrate(_node, _) do
      []
    end

    def valued_entity_resolve_type(_, _), do: :photo
  end

  test "can extend schema" do
    schema_declaration = ExtendedSchema.__absinthe_schema_declaration__()

    assert [%{name: "feature"}] = schema_declaration.directives

    assert [%{name: "query"}, %{name: "mutation", type: %{name: "MyMutationRootType"}}] =
             schema_declaration.field_definitions
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

  test "raises when definition types do not match" do
    schema = """
    defmodule KeywordExtend do
      use Absinthe.Schema

      query do
      end

      import_sdl "
      enum Direction {
        NORTH
        EAST
      }

      extend union Direction = WEST
      "
    end
    """

    error = ~r/Type extension type does not match definition type for :direction./

    assert_raise(Absinthe.Schema.Error, error, fn ->
      Code.eval_string(schema, [], __ENV__)
    end)
  end

  defmodule ImportedSchema do
    use Absinthe.Schema.Notation

    import_sdl """
    extend enum Direction {
      NORTH
    }
    """
  end

  defmodule ImportingSchema do
    use Absinthe.Schema

    query do
      field :foo, :string
    end

    import_type_extensions ImportedSchema

    import_sdl """
    enum Direction {
      SOUTH
    }
    """
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
