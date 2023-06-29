defmodule Absinthe.Schema.ManipulationTest do
  use Absinthe.Case, async: true

  alias Absinthe.Phase.Schema.Validation.TypeNamesAreReserved

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

  defmodule CustomIntrospectionTypes do
    use Absinthe.Schema.Notation

    object :custom_introspection_helper do
      description "Simple Helper Object used to define blueprint fields"

      field :simple_string, :string do
        description "custom introspection field"

        resolve fn _, %{schema: schema} ->
          {:ok, "This is a new introspection type on #{inspect(schema)}"}
        end
      end

      field :some_string_meta, :string do
        description "Expose some_string_meta"

        resolve fn _,
                   %{
                     source: source
                   } ->
          private = source.__private__ || []
          meta_items = private[:meta] || []

          {:ok, meta_items[:some_string_meta]}
        end
      end
    end
  end

  defmodule MyAppWeb.CustomSchemaPhase do
    alias Absinthe.{Phase, Pipeline, Blueprint}

    # Add this module to the pipeline of phases
    # to run on the schema
    def pipeline(pipeline) do
      Pipeline.insert_after(pipeline, Phase.Schema.TypeImports, __MODULE__)
    end

    # Here's the blueprint of the schema, let's do whatever we want with it.
    def run(blueprint = %Blueprint{}, _) do
      custom_introspection_types = Blueprint.types_by_name(CustomIntrospectionTypes)
      custom_introspection_fields = custom_introspection_types["CustomIntrospectionHelper"]

      simple_string_field =
        Blueprint.find_field(custom_introspection_fields, "simple_string")
        |> TypeNamesAreReserved.make_reserved()

      some_string_meta_field =
        Blueprint.find_field(custom_introspection_fields, "some_string_meta")
        |> TypeNamesAreReserved.make_reserved()

      blueprint =
        blueprint
        |> Blueprint.extend_fields(ExtTypes)
        |> Blueprint.add_field("__Type", simple_string_field)
        |> Blueprint.add_field("__Field", simple_string_field)
        |> Blueprint.add_field("__Field", some_string_meta_field)

      {:ok, blueprint}
    end
  end

  defmodule MyAppWeb.CustomSchemaEnumTypes do
    alias Absinthe.Blueprint.Schema
    alias Absinthe.Schema.Notation
    alias Absinthe.{Blueprint, Pipeline, Phase}

    def pipeline(pipeline) do
      Pipeline.insert_after(pipeline, Phase.Schema.TypeImports, __MODULE__)
    end

    def run(blueprint = %Blueprint{}, _) do
      %{schema_definitions: [schema]} = blueprint

      new_enum = build_dynamic_enum()

      schema =
        Map.update!(schema, :type_definitions, fn type_definitions ->
          [new_enum | type_definitions]
        end)

      {:ok, %{blueprint | schema_definitions: [schema]}}
    end

    def build_dynamic_enum() do
      %Schema.EnumTypeDefinition{
        name: "Categories",
        identifier: :categories,
        module: __MODULE__,
        __reference__: Notation.build_reference(__ENV__),
        values: [
          %Schema.EnumValueDefinition{
            identifier: :foo,
            value: :foo,
            name: "FOO",
            module: __MODULE__,
            __reference__: Notation.build_reference(__ENV__)
          },
          %Schema.EnumValueDefinition{
            identifier: :bar,
            value: :bar,
            name: "BAR",
            module: __MODULE__,
            __reference__: Notation.build_reference(__ENV__)
          }
        ]
      }
    end
  end

  defmodule MyAppWeb.Schema do
    use Absinthe.Schema

    @pipeline_modifier MyAppWeb.CustomSchemaPhase
    @pipeline_modifier MyAppWeb.CustomSchemaEnumTypes

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

      field :non_dyn_string, :string, meta: [some_string_meta: "non_dyn_string meta"] do
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

  test "enum types work" do
    q = """
    query {
      __type(name: "Categories") {
        enumValues {
          name
        }
      }
    }
    """

    expected = %{data: %{"__type" => %{"enumValues" => [%{"name" => "BAR"}, %{"name" => "FOO"}]}}}

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

  test "Custom introspection works" do
    q = """
    query {
      __type(name: "SomeObj") {
        __simple_string
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
          "__simple_string" =>
            "This is a new introspection type on Absinthe.Schema.ManipulationTest.MyAppWeb.Schema",
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

  test "Exposing meta data via introspection works" do
    q = """
    query {
      __type(name: "SomeObj") {
        fields {
          name
          type {
            name
          }
          __some_string_meta
        }
      }
    }
    """

    expected = %{
      data: %{
        "__type" => %{
          "fields" => [
            %{
              "name" => "someInteger",
              "type" => %{"name" => "Int"},
              "__some_string_meta" => "some_integer meta"
            },
            %{
              "name" => "someString",
              "type" => %{"name" => "String"},
              "__some_string_meta" => "some_string meta"
            }
          ]
        }
      }
    }

    actual = Absinthe.run!(q, MyAppWeb.Schema)

    assert expected == actual
  end

  test "Extending Objects works" do
    q = """
    query {
      __type(name: "SomeDynObj") {
        fields {
          name
          type {
            name
          }
          __some_string_meta
        }
      }
    }
    """

    expected = %{
      data: %{
        "__type" => %{
          "fields" => [
            %{
              "name" => "nonDynInteger",
              "type" => %{"name" => "Int"},
              "__some_string_meta" => "non_dyn_integer meta"
            },
            %{
              "name" => "nonDynString",
              "type" => %{"name" => "String"},
              "__some_string_meta" => "non_dyn_string meta"
            },
            %{
              "name" => "someDynInteger",
              "type" => %{"name" => "Int"},
              "__some_string_meta" => "some_dyn_integer meta"
            },
            %{
              "name" => "someDynString",
              "type" => %{"name" => "String"},
              "__some_string_meta" => "some_dyn_string meta"
            }
          ]
        }
      }
    }

    actual = Absinthe.run!(q, MyAppWeb.Schema)

    assert expected == actual
  end
end
