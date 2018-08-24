defmodule Absinthe.Phase.Schema.Imports do
  def run(blueprint, _opts) do
    blueprint =
      Map.update!(blueprint, :schema_definitions, fn defs ->
        for def <- defs, do: handle_imports(def)
      end)

    {:ok, blueprint}
  end

  @default_imports [
    {Absinthe.Type.BuiltIns.Scalars, []},
    {Absinthe.Type.BuiltIns.Directives, []},
    {Absinthe.Type.BuiltIns.Introspection, []}
  ]
  def handle_imports(def) do
    types = do_imports(@default_imports ++ def.imports, def.type_definitions)
    # special casing for the moment.
    [other_def] = Absinthe.Type.BuiltIns.Directives.__absinthe_blueprint__().schema_definitions
    directives = def.directive_definitions ++ other_def.directive_definitions
    %{def | type_definitions: types, directive_definitions: directives}
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
