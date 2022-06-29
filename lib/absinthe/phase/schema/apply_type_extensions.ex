defmodule Absinthe.Phase.Schema.ApplyTypeExtensions do
  @moduledoc false

  @behaviour Absinthe.Phase
  alias Absinthe.Blueprint
  alias Absinthe.Blueprint.Schema

  @spec run(Blueprint.t(), Keyword.t()) :: {:ok, Blueprint.t()}
  def run(input, _options \\ []) do
    blueprint = process(input)
    {:ok, blueprint}
  end

  defp process(blueprint = %Blueprint{}) do
    %{blueprint | schema_definitions: update_schema_defs(blueprint.schema_definitions)}
  end

  def update_schema_defs(schema_definitions) do
    for schema_def = %{
          type_definitions: type_definitions,
          type_extensions: type_extensions,
          schema_declaration: schema_declaration
        } <-
          schema_definitions do
      {type_definitions, type_extensions} =
        apply_type_extensions(type_definitions, type_extensions, [])

      {[schema_declaration], type_extensions} =
        apply_type_extensions([schema_declaration], type_extensions, [])

      %{
        schema_def
        | schema_declaration: schema_declaration,
          type_definitions: type_definitions,
          type_extensions: type_extensions
      }
    end
  end

  defp apply_type_extensions([type_definition | type_definitions], type_extensions, type_defs) do
    {type_extensions, type_definition} =
      Enum.map_reduce(type_extensions, type_definition, &apply_extension/2)

    apply_type_extensions(type_definitions, type_extensions, [type_definition | type_defs])
  end

  defp apply_type_extensions([], type_extensions, type_definitions) do
    {type_definitions, type_extensions}
  end

  defp apply_extension(
         %Schema.TypeExtensionDefinition{
           definition: %Schema.InputObjectTypeDefinition{identifier: identifier}
         } = extension,
         %Schema.InputObjectTypeDefinition{identifier: identifier} = definition
       ) do
    {extension,
     %{
       definition
       | directives: definition.directives ++ extension.definition.directives,
         fields: definition.fields ++ extension.definition.fields
     }}
  end

  defp apply_extension(
         %Schema.TypeExtensionDefinition{
           definition: %Schema.InterfaceTypeDefinition{identifier: identifier}
         } = extension,
         %Schema.InterfaceTypeDefinition{identifier: identifier} = definition
       ) do
    {extension,
     %{
       definition
       | directives: definition.directives ++ extension.definition.directives,
         fields: definition.fields ++ extension.definition.fields,
         interfaces: definition.interfaces ++ extension.definition.interfaces
     }}
  end

  defp apply_extension(
         %Schema.TypeExtensionDefinition{
           definition: %Schema.ObjectTypeDefinition{identifier: identifier}
         } = extension,
         %Schema.ObjectTypeDefinition{identifier: identifier} = definition
       ) do
    {extension,
     %{
       definition
       | directives: definition.directives ++ extension.definition.directives,
         fields: definition.fields ++ extension.definition.fields,
         interfaces: definition.interfaces ++ extension.definition.interfaces
     }}
  end

  defp apply_extension(
         %Schema.TypeExtensionDefinition{
           definition: %Schema.ScalarTypeDefinition{identifier: identifier}
         } = extension,
         %Schema.ScalarTypeDefinition{identifier: identifier} = definition
       ) do
    {extension,
     %{
       definition
       | directives: definition.directives ++ extension.definition.directives
     }}
  end

  defp apply_extension(
         %Schema.TypeExtensionDefinition{
           definition: %Schema.UnionTypeDefinition{identifier: identifier}
         } = extension,
         %Schema.UnionTypeDefinition{identifier: identifier} = definition
       ) do
    {extension,
     %{
       definition
       | types: definition.types ++ extension.definition.types,
         directives: definition.directives ++ extension.definition.directives
     }}
  end

  defp apply_extension(
         %Schema.TypeExtensionDefinition{
           definition: %Schema.EnumTypeDefinition{identifier: identifier}
         } = extension,
         %Schema.EnumTypeDefinition{identifier: identifier} = definition
       ) do
    {extension,
     %{
       definition
       | values: definition.values ++ extension.definition.values,
         directives: definition.directives ++ extension.definition.directives
     }}
  end

  defp apply_extension(
         %Schema.TypeExtensionDefinition{
           definition: %Schema.SchemaDeclaration{}
         } = extension,
         %Schema.SchemaDeclaration{} = definition
       ) do
    {extension,
     %{
       definition
       | field_definitions:
           definition.field_definitions ++ extension.definition.field_definitions,
         directives: definition.directives ++ extension.definition.directives
     }}
  end

  defp apply_extension(
         %{definition: %{identifier: identifier} = extension},
         %{identifier: identifier} = definition
       ) do
    extension = Absinthe.Phase.put_error(extension, error(definition, extension))

    {extension, definition}
  end

  defp apply_extension(extension, definition) do
    {extension, definition}
  end

  defp error(%definition_type{} = definition, %extension_type{} = extension_definition) do
    expected_type = Schema.struct_to_kind(definition_type)
    extension_type = Schema.struct_to_kind(extension_type)

    %Absinthe.Phase.Error{
      message: """
      Type extension type does not match definition type for #{inspect(definition.identifier)}.

      Expected an #{expected_type} but got a #{extension_type}.
      """,
      locations: [extension_definition.__reference__.location],
      phase: __MODULE__
    }
  end
end
