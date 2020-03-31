if Code.ensure_loaded?(:persistent_term) do
  defmodule Absinthe.Phase.Schema.PopulatePersistentTerm do
    @moduledoc false

    alias Absinthe.Blueprint.Schema

    def run(blueprint, opts) do
      %{schema_definitions: [schema]} = blueprint

      type_list =
        Map.new(schema.type_definitions, fn type_def ->
          {type_def.identifier, type_def.name}
        end)

      types_map =
        schema.type_artifacts
        |> Enum.flat_map(fn type -> [{type.identifier, type}, {type.name, type}] end)
        |> Map.new()

      referenced_types =
        for type_def <- schema.type_definitions,
            type_def.__private__[:__absinthe_referenced__],
            into: %{},
            do: {type_def.identifier, type_def.name}

      directive_list =
        Map.new(schema.directive_definitions, fn type_def ->
          {type_def.identifier, type_def.name}
        end)

      directives_map =
        schema.directive_artifacts
        |> Enum.flat_map(fn type -> [{type.identifier, type}, {type.name, type}] end)
        |> Map.new()

      prototype_schema = Keyword.fetch!(opts, :prototype_schema)

      metadata = build_metadata(schema)

      implementors = build_implementors(schema)

      schema_content = %{
        __absinthe_types__: %{
          referenced: referenced_types,
          all: type_list
        },
        __absinthe_directives__: directive_list,
        __absinthe_interface_implementors__: implementors,
        __absinthe_prototype_schema__: prototype_schema,
        __absinthe_type__: types_map,
        __absinthe_directive__: directives_map,
        __absinthe_reference__: metadata
      }

      schema_name = opts[:schema] || raise "no schema name provided"

      put_schema(schema_name, schema_content)

      {:ok, blueprint}
    end

    @dialyzer {:nowarn_function, [put_schema: 2]}
    defp put_schema(schema_name, content) do
      :persistent_term.put(
        {Absinthe.Schema.PersistentTerm, schema_name},
        content
      )
    end

    def build_metadata(schema) do
      for type <- schema.type_definitions do
        {type.identifier, type.__reference__}
      end
    end

    defp build_implementors(schema) do
      schema.type_definitions
      |> Enum.filter(&match?(%Schema.InterfaceTypeDefinition{}, &1))
      |> Map.new(fn iface ->
        implementors =
          Schema.InterfaceTypeDefinition.find_implementors(iface, schema.type_definitions)

        {iface.identifier, Enum.sort(implementors)}
      end)
    end
  end
else
  defmodule Absinthe.Phase.Schema.PopulatePersistentTerm do
    def run(_, _) do
      raise "This phase requires OTP >= 21.2"
    end
  end
end
