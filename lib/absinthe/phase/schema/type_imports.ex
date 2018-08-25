defmodule Absinthe.Phase.Schema.TypeImports do

  @moduledoc false

  def run(blueprint, _opts) do
    blueprint =
      Map.update!(blueprint, :schema_definitions, fn schemas ->
        for schema <- schemas, do: handle_imports(schema)
      end)

    {:ok, blueprint}
  end

  @default_imports [
    {Absinthe.Type.BuiltIns.Scalars, []},
    {Absinthe.Type.BuiltIns.Directives, []},
    {Absinthe.Type.BuiltIns.Introspection, []}
  ]
  def handle_imports(schema) do
    types = do_imports(@default_imports ++ schema.imports, schema.type_definitions)
    # special casing the import of the built in directives
    [builtins] = Absinthe.Type.BuiltIns.Directives.__absinthe_blueprint__().schema_definitions
    directives = schema.directive_definitions ++ builtins.directive_definitions
    %{schema | type_definitions: types, directive_definitions: directives}
  end

  defp do_imports([], types) do
    types
  end

  defp do_imports([{module, opts} | rest], acc) do
    [other_def] = module.__absinthe_blueprint__.schema_definitions

    rejections = MapSet.new([:query, :mutation, :subscription] ++ Keyword.get(opts, :except, []))

    types = Enum.reject(other_def.type_definitions, &(&1.identifier in rejections))

    case Keyword.fetch(opts, :only) do
      {:ok, selections} ->
        Enum.filter(types, &(&1.identifier in selections))

      _ ->
        types
    end

    do_imports(other_def.imports ++ rest, types ++ acc)
  end
end
