defmodule Absinthe.Phase.Schema.ApplyDeclaration do
  @moduledoc false

  use Absinthe.Phase
  alias Absinthe.Blueprint

  @type operation :: :query | :mutation | :subscription

  @type root_mappings :: %{operation() => Blueprint.TypeReference.Name.t()}

  def run(blueprint, _opts) do
    blueprint = process(blueprint)
    {:ok, blueprint}
  end

  # Apply schema declaration to each schema definition
  @spec process(blueprint :: Blueprint.t()) :: Blueprint.t()
  defp process(blueprint = %Blueprint{}) do
    %{
      blueprint
      | schema_definitions: Enum.map(blueprint.schema_definitions, &process_schema_definition/1)
    }
  end

  # Strip the schema declaration out of the schema's type definitions and apply it
  @spec process_schema_definition(schema_definition :: Blueprint.Schema.SchemaDefinition.t()) ::
          Blueprint.Schema.SchemaDefinition.t()
  defp process_schema_definition(schema_definition) do
    {declarations, type_defs} =
      Enum.split_with(
        schema_definition.type_definitions,
        &match?(%Blueprint.Schema.SchemaDeclaration{}, &1)
      )

    # Remove declaration
    schema_definition = %{schema_definition | type_definitions: type_defs}

    case declarations do
      [declaration] ->
        root_mappings =
          declaration
          |> extract_root_mappings

        %{
          schema_definition
          | type_definitions:
              Enum.map(schema_definition.type_definitions, &maybe_mark_root(&1, root_mappings))
        }

      [] ->
        schema_definition

      [_first | extra_declarations] ->
        extra_declarations
        |> Enum.reduce(schema_definition, fn declaration, acc ->
          acc
          |> put_error(error(declaration))
        end)
    end
  end

  # Generate an error for extraneous schema declarations
  @spec error(declaration :: Blueprint.Schema.SchemaDeclaration.t()) :: Absinthe.Phase.Error.t()
  defp error(declaration) do
    %Absinthe.Phase.Error{
      message:
        "More than one schema declaration found. Only one instance of `schema' should be present in SDL.",
      locations: [declaration.__reference__.location],
      phase: __MODULE__
    }
  end

  # Extract the declared root type names
  @spec extract_root_mappings(declaration :: Blueprint.Schema.SchemaDeclaration.t()) ::
          root_mappings()
  defp extract_root_mappings(declaration) do
    for field_def <- declaration.field_definitions,
        field_def.identifier in ~w(query mutation subscription)a,
        into: %{} do
      {field_def.identifier, field_def.type}
    end
  end

  # If the type definition is declared as a root type, set the identifier appropriately
  @spec maybe_mark_root(type_def :: Blueprint.Schema.t(), root_mappings :: root_mappings()) ::
          Blueprint.Schema.t()
  defp maybe_mark_root(%Blueprint.Schema.ObjectTypeDefinition{} = type_def, root_mappings) do
    case operation_root_identifier(type_def, root_mappings) do
      nil ->
        type_def

      identifier ->
        %{type_def | identifier: identifier}
    end
  end

  defp maybe_mark_root(type_def, _root_mappings), do: type_def

  # Determine which, if any, root identifier should be applied to an object type definitiona
  @spec operation_root_identifier(
          type_def :: Blueprint.Schema.ObjectTypeDefinition.t(),
          root_mappings :: root_mappings()
        ) :: nil | operation()
  defp operation_root_identifier(type_def, root_mappings) do
    match_name = type_def.name

    Enum.find_value(root_mappings, fn
      {ident, %{name: ^match_name}} ->
        ident

      _ ->
        false
    end)
  end
end
