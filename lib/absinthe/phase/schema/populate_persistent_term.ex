defmodule Absinthe.Phase.Schema.PopulatePersistentTerm do
  @moduledoc false

  alias Absinthe.Blueprint.Schema

  def run(blueprint, opts) do
    %{schema_definitions: [schema]} = blueprint

    type_ident_list =
      Map.new(schema.type_definitions, fn type_def ->
        {type_def.identifier, type_def.name}
      end)

    type_name_list =
      Map.new(schema.type_definitions, fn type_def ->
        {type_def.name, type_def.name}
      end)

    referenced_types =
      for type_def <- schema.type_definitions,
          type_def.__private__[:__absinthe_referenced__],
          into: %{},
          do: {type_def.identifier, type_def.name}

    directive_list =
      Map.new(schema.directive_definitions, fn type_def ->
        {type_def.identifier, type_def.name}
      end)

    prototype_schema = Keyword.fetch!(opts, :prototype_schema)

    metadata = build_metadata(schema)

    implementors = build_implementors(schema)

    schema = %{}

    persist_kv(opts[:schema], :__absinthe_directive__, directive_list)
    persist_kv(opts[:schema], :__absinthe_type__, type_ident_list)
    persist_kv(opts[:schema], :__absinthe_type__, type_name_list)

    {:ok, blueprint}
  end

  defp persist_kv(schema, prop, kv) do
    for {k, v} <- kv do
      pk = {Absinthe.Schema.PersistentTerm, schema, prop, k}
      IO.inspect(pk)
      :persistent_term.put(pk, v)
    end
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
