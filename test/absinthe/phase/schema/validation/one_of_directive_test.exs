defmodule Absinthe.Phase.Schema.Validation.OneOfDirectiveTest do
  use Absinthe.Case, async: true

  alias Absinthe.Phase.Schema.Validation.OneOfDirective
  alias Absinthe.Pipeline

  defmodule Modifier do
    def pipeline(pipeline), do: Pipeline.upto(pipeline, OneOfDirective)
  end

  defmodule Schema do
    use Absinthe.Schema

    @pipeline_modifier Modifier

    input_object :no_directive_input do
      field :id, non_null(:id)
    end

    input_object :valid_input do
      directive :one_of
      field :id, :id
      field :name, :string
    end

    input_object :single_field_input do
      directive :one_of
      field :id, :id
    end

    input_object :non_null_field_input do
      directive :one_of
      field :id, non_null(:id)
      field :name, :string
    end

    query do
      field :valid, :boolean do
        arg :no_directive, :no_directive_input
        arg :valid, :valid_input
        arg :single_field, :single_field_input
        arg :non_null_field, :non_null_field_input
      end
    end
  end

  setup_all do
    {:ok, blueprint} = OneOfDirective.run(Schema.__absinthe_blueprint__())
    [blueprint: blueprint]
  end

  describe "run/2" do
    test "field without directive is a noop", %{blueprint: blueprint} do
      assert %{errors: []} = find_definition(blueprint, :no_directive_input)
    end

    test "valid use is a noop", %{blueprint: blueprint} do
      assert %{errors: []} = find_definition(blueprint, :valid_input)
    end

    test "on an object with a single field adds an error", %{blueprint: blueprint} do
      assert %{errors: [error]} = find_definition(blueprint, :single_field_input)
      assert %Absinthe.Phase.Error{message: message, phase: OneOfDirective} = error

      assert message =~
               "The oneOf directive is only valid on input types with more then one field."
    end

    test "on an object with a non_null field adds an error", %{blueprint: blueprint} do
      assert %{errors: [error]} = find_definition(blueprint, :non_null_field_input)
      assert %Absinthe.Phase.Error{message: message, phase: OneOfDirective} = error

      assert message =~
               "The oneOf directive is only valid on input types with all nullable fields."
    end
  end

  defp find_definition(blueprint, identifier) do
    blueprint.schema_definitions
    |> Enum.flat_map(& &1.type_definitions)
    |> Enum.filter(&is_struct/1)
    |> Enum.find(&(&1.identifier == identifier))
  end
end
