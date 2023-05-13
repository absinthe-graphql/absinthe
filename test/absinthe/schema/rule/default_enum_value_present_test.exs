defmodule Absinthe.Schema.Rule.DefaultEnumValuePresentTest do
  use Absinthe.Case, async: true

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
end
