defmodule Absinthe.Phase.Schema.Imports do
  def run(blueprint, opts) do
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
    other_types =
      Enum.flat_map(@default_imports ++ def.imports, fn {module, _} ->
        [other_def] = module.__absinthe_blueprint__.schema_definitions

        Enum.reject(other_def.types, fn type ->
          type.identifier in [:query, :mutation, :subscription]
        end)
      end)

    %{def | types: other_types ++ def.types}
  end
end
