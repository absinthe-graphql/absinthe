defmodule Absinthe.Schema.Rule.DefaultEnumValuePresentTest do
  use Absinthe.Case, async: true

  alias Absinthe.Blueprint.Schema.{
    EnumTypeDefinition,
    EnumValueDefinition,
    InputValueDefinition,
    SchemaDefinition
  }

  alias Absinthe.Blueprint.TypeReference.{Identifier, NonNull}
  alias Absinthe.Blueprint.TypeReference.List, as: ListType
  alias Absinthe.Phase.Schema.Validation.DefaultEnumValuePresent

  describe "validate_defaults/3" do
    setup do
      enum = %EnumTypeDefinition{
        name: "MovieGenre",
        identifier: :movie_genre,
        values: [
          %EnumValueDefinition{name: "ACTION", identifier: :action, value: :action},
          %EnumValueDefinition{name: "COMEDY", identifier: :comedy, value: :comedy},
          %EnumValueDefinition{name: "SF", identifier: :sf, value: :sf}
        ]
      }

      schema = %SchemaDefinition{type_definitions: [enum]}

      {:ok, enums: %{movie_genre: enum}, schema: schema}
    end

    test "is enforced when a non-null enum list default contains nil", %{
      enums: enums,
      schema: schema
    } do
      type = list_of(non_null(:movie_genre))
      node = input_value(type: type, default_value: [:action, nil])

      result = DefaultEnumValuePresent.validate_defaults(node, enums, schema)

      assert [
               %Absinthe.Phase.Error{
                 phase: DefaultEnumValuePresent,
                 extra: %{default_value: nil, type: ^type}
               }
             ] = result.errors
    end

    test "passes when a nullable enum list default contains nil", %{enums: enums, schema: schema} do
      node = input_value(type: list_of(:movie_genre), default_value: [:action, nil])

      assert DefaultEnumValuePresent.validate_defaults(node, enums, schema) == node
    end
  end

  describe "SDL schema" do
    test "is enforced when the default_value is not in the enum" do
      schema = """
      defmodule BadColorSchemaSdl do
        use Absinthe.Schema

        import_sdl "
        enum Channel {
          RED
          GREEN
        }

        type Query {
          info(channel: Channel! = OTHER): Channel
        }
        "
      end
      """

      error = ~r/The default_value for an enum must be present in the enum values/

      assert_raise(Absinthe.Schema.Error, error, fn ->
        Code.eval_string(schema)
      end)
    end

    test "is enforced when the default_value is a list of enums and some items are not in the enum" do
      schema = """
      defmodule MovieSchemaSdl do
        use Absinthe.Schema


        import_sdl "
        enum MovieGenre {
          ACTION
          COMEDY
          SF
        }

        type Query {
          movies(genres: [MovieGenre!]! = [ACTION, OTHER]): [MovieGenre!]!
        }
        "
      end
      """

      error = ~r/The default_value for an enum must be present in the enum values/

      assert_raise(Absinthe.Schema.Error, error, fn ->
        Code.eval_string(schema)
      end)
    end

    test "passes when the default_value is a list and that list is a valid enum value" do
      schema = """
      defmodule CorrectCatSchemSdl do
        use Absinthe.Schema

        import_sdl "
        enum CatOrderBy {
          NAME_ASC
          NAME_DESC_INSERTED_AT_ASC
        }

        type Query {
          cat(orderBy: [CatOrderBy!] = [NAME_ASC]): [Cat!]!
        }

        type Cat {
          name: String
        }
        "
      end
      """

      assert Code.eval_string(schema)
    end
  end

  describe "macro schema" do
    test "is enforced when the default_value is not in the enum" do
      schema = """
      defmodule BadColorSchema do
        use Absinthe.Schema

        @names %{
          r: "RED"
        }

        query do

          field :info,
            type: :channel_info,
            args: [
              channel: [type: non_null(:channel), default_value: :OTHER],
            ],
            resolve: fn
              %{channel: channel}, _ ->
              {:ok, %{name: @names[channel]}}
            end

        end

        enum :channel do
          value :red, as: :r
          value :green, as: :g
        end

        object :channel_info do
          field :name, :string
        end
      end
      """

      error = ~r/The default_value for an enum must be present in the enum values/

      assert_raise(Absinthe.Schema.Error, error, fn ->
        Code.eval_string(schema)
      end)
    end

    test "is enforced when the default_value is a list of enums and some items are not in the enum" do
      schema = """
      defmodule MovieSchema do
        use Absinthe.Schema

        query do

          field :movies,
            type: non_null(list_of(non_null(:movie_genre))),
            args: [
              genres: [type: non_null(list_of(non_null(:movie_genre))), default_value: [:action, :OTHER]],
            ],
            resolve: fn
              %{genres: _}, _ -> {:ok, []}
            end

        end

        enum :movie_genre do
          value :action, as: :action
          value :comedy, as: :comedy
          value :sf, as: :sf
        end

        object :movie do
          field :name, :string
        end
      end
      """

      error = ~r/The default_value for an enum must be present in the enum values/

      assert_raise(Absinthe.Schema.Error, error, fn ->
        Code.eval_string(schema)
      end)
    end

    test "passes when the default_value is a list and that list is a valid enum value" do
      schema = """
      defmodule CorrectCatSchema do
        use Absinthe.Schema

        query do

          field :cats,
            type: non_null(list_of(non_null(:cat))),
            args: [
              order_by: [type: non_null(:cat_order_by), default_value: [{:asc, :name}]],
            ],
            resolve: fn
              %{order_by: _}, _ -> {:ok, []}
            end

        end

        enum :cat_order_by do
          value :name_asc, as: [{:asc, :name}]
          value :name_desc_inserted_at_asc, as: [{:desc, :name}, {:asc, :inserted_at}]
        end

        object :cat do
          field :name, :string
        end
      end
      """

      assert Code.eval_string(schema)
    end
  end

  defp input_value(attrs) do
    attrs
    |> Keyword.put_new(:__reference__, reference())
    |> then(&struct!(InputValueDefinition, &1))
  end

  defp list_of(type), do: %ListType{of_type: type_reference(type)}

  defp non_null(type), do: %NonNull{of_type: type_reference(type)}

  defp type_reference(%_{} = type), do: type
  defp type_reference(identifier) when is_atom(identifier), do: %Identifier{id: identifier}

  defp reference do
    %{location: %{file: __ENV__.file, line: __ENV__.line}}
  end
end
