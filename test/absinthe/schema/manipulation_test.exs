defmodule Absinthe.Schema.ManipulationTest do
  use Absinthe.Case, async: true
  require IEx

  defmodule ExtTypes do
    use Absinthe.Schema.Notation

    object :some_dyn_obj do
      field :some_dyn_integer, :integer do
        meta :some_string_meta, "some_dyn_integer meta"
      end

      field :some_dyn_string, :string do
        meta :some_string_meta, "some_dyn_string meta"
        resolve fn _, _ -> {:ok, "some_string_val"} end
      end
    end
  end

  defmodule MyAppWeb.CustomSchemaPhase do
    alias Absinthe.{Phase, Pipeline, Blueprint}
    alias Absinthe.Type

    # Add this module to the pipeline of phases
    # to run on the schema
    def pipeline(pipeline) do
      Pipeline.insert_after(pipeline, Phase.Schema.TypeImports, __MODULE__)
    end

    # Here's the blueprint of the schema, let's do whatever we want with it.
    def run(blueprint = %Blueprint{}, _) do
      Blueprint.extend_fields(blueprint, ExtTypes)
    end
  end

  defmodule MyAppWeb.Schema do
    use Absinthe.Schema
    alias Absinthe.Type

    #@pipeline_modifier MyAppWeb.CustomSchemaPhase

    def introspection_field("simple_string") do
      %Type.Field{
        name: "__simple_string",
        type: :string,
        description: "customer introspection field",
        middleware: [
          Absinthe.Resolution.resolver_spec(fn _, %{schema: schema} ->
            {:ok, "This is a new introspection type on #{inspect(schema)}"}
          end)
        ]
      }
    end

    def introspection_field("some_string_meta") do
      %Type.Field{
        name: "__some_string_meta",
        type: :string,
        description: "Expose some_string_meta",
        middleware: [
          Absinthe.Resolution.resolver_spec(fn _,
                                               %{
                                                 source: source
                                               } ->
            private = source[:__private__] || []
            meta_items = private[:meta] || []

            {:ok, meta_items[:some_string_meta]}
          end)
        ]
      }
    end

    object :some_obj do
      field :some_integer, :integer do
        meta :some_string_meta, "some_integer meta"
      end

      field :some_string, :string do
        meta :some_string_meta, "some_string meta"
        resolve fn _, _ -> {:ok, "some_string_val"} end
      end
    end

    object :some_dyn_obj do
      field :non_dyn_integer, :integer do
        meta :some_string_meta, "non_dyn_integer meta"
      end

      field :non_dyn_string, :string do
        meta :some_string_meta, "non_dyn_string meta"
        resolve fn _, _ -> {:ok, "some_string_val"} end
      end
    end

    query do
      field :some_field, :some_obj do
        meta :some_field_meta, "some field meta"
        resolve fn _, _ -> {:ok, %{some_integer: 1}} end
      end
    end
  end

  test "Schema works" do
    q = """
    query {
      some_field {
        some_integer
        some_string
      }
    }
    """

    expected = %{
      data: %{"some_field" => %{"some_integer" => 1, "some_string" => "some_string_val"}}
    }

    actual = Absinthe.run!(q, MyAppWeb.Schema)

    assert expected == actual
  end

  test "Introspection works" do
    q = """
    query {
      __type(name: "SomeObj") {
        fields {
          name
          type {
            name
          }
        }
      }
    }
    """

    expected = %{
      data: %{
        "__type" => %{
          "fields" => [
            %{"name" => "someInteger", "type" => %{"name" => "Int"}},
            %{"name" => "someString", "type" => %{"name" => "String"}}
          ]
        }
      }
    }

    actual = Absinthe.run!(q, MyAppWeb.Schema)

    assert expected == actual
  end

  # test "Custom introspection works" do
  #   q = """
  #   query {
  #     __type(name: "SomeObj") {
  #       __simple_string
  #       fields {
  #         name
  #         type {
  #           name
  #         }
  #       }
  #     }
  #   }
  #   """

  #   expected = %{
  #     data: %{
  #       "__type" => %{
  #         "__simple_string" =>
  #           "This is a new introspection type on Absinthe.Schema.ManipulationTest.MyAppWeb.Schema",
  #         "fields" => [
  #           %{"name" => "someInteger", "type" => %{"name" => "Int"}},
  #           %{"name" => "someString", "type" => %{"name" => "String"}}
  #         ]
  #       }
  #     }
  #   }

  #   actual = Absinthe.run!(q, MyAppWeb.Schema)

  #   assert expected == actual
  # end

  # test "Exposing meta data via introspection works" do
  #   q = """
  #   query {
  #     __type(name: "SomeObj") {
  #       fields {
  #         name
  #         type {
  #           name
  #         }
  #         __some_string_meta
  #       }
  #     }
  #   }
  #   """

  #   expected = %{
  #     data: %{
  #       "__type" => %{
  #         "fields" => [
  #           %{
  #             "name" => "someInteger",
  #             "type" => %{"name" => "Int"},
  #             "__some_string_meta" => "some_integer meta"
  #           },
  #           %{
  #             "name" => "someString",
  #             "type" => %{"name" => "String"},
  #             "__some_string_meta" => "some_string meta"
  #           }
  #         ]
  #       }
  #     }
  #   }

  #   actual = Absinthe.run!(q, MyAppWeb.Schema)

  #   assert expected == actual
  # end

  # test "Extending Objects works" do
  #   q = """
  #   query {
  #     __type(name: "SomeDynObj") {
  #       fields {
  #         name
  #         type {
  #           name
  #         }
  #         __some_string_meta
  #       }
  #     }
  #   }
  #   """

  #   expected = %{
  #     data: %{
  #       "__type" => %{
  #         "fields" => [
  #           %{
  #             "name" => "nonDynInteger",
  #             "type" => %{"name" => "Int"},
  #             "__some_string_meta" => "non_dyn_integer meta"
  #           },
  #           %{
  #             "name" => "nonDynString",
  #             "type" => %{"name" => "String"},
  #             "__some_string_meta" => "non_dyn_string meta"
  #           },
  #           %{
  #             "name" => "someDynInteger",
  #             "type" => %{"name" => "Int"},
  #             "__some_string_meta" => "some_dyn_integer meta"
  #           },
  #           %{
  #             "name" => "someDynString",
  #             "type" => %{"name" => "String"},
  #             "__some_string_meta" => "some_dyn_string meta"
  #           }
  #         ]
  #       }
  #     }
  #   }

  #   actual = Absinthe.run!(q, MyAppWeb.Schema)

  #   assert expected == actual
  # end
end
