defmodule Absinthe.Phase.Schema.TypeImports do
  @moduledoc false

  use Absinthe.Phase
  alias Absinthe.Blueprint

  alias Absinthe.Blueprint.Schema

  def run(blueprint, _opts) do
    blueprint = Blueprint.prewalk(blueprint, &handle_imports/1)
    {:ok, blueprint}
  end

  @default_imports [
    {Absinthe.Type.BuiltIns.Scalars, []},
    {Absinthe.Type.BuiltIns.Directives, []},
    {Absinthe.Type.BuiltIns.Introspection, []}
  ]
  def handle_imports(%Schema.SchemaDefinition{} = schema) do
    {types, schema} =
      do_imports(@default_imports ++ schema.imports, schema.type_definitions, schema)

    # special casing the import of the built in directives
    [builtins] = Absinthe.Type.BuiltIns.Directives.__absinthe_blueprint__().schema_definitions
    directives = schema.directive_definitions ++ builtins.directive_definitions
    {:halt, %{schema | type_definitions: types, directive_definitions: directives}}
  end

  def handle_imports(node), do: node

  defp do_imports([], types, schema) do
    {types, schema}
  end

  defp do_imports([{module, opts} | rest], acc, schema) do
    case Code.ensure_compiled(module) do
      {:module, module} ->
        [other_def] = module.__absinthe_blueprint__.schema_definitions

        rejections =
          MapSet.new([:query, :mutation, :subscription] ++ Keyword.get(opts, :except, []))

        types = Enum.reject(other_def.type_definitions, &(&1.identifier in rejections))

        types =
          case Keyword.fetch(opts, :only) do
            {:ok, selections} ->
              Enum.filter(types, &(&1.identifier in selections))

            _ ->
              types
          end

        do_imports(other_def.imports ++ rest, types ++ acc, schema)

      {:error, reason} ->
        do_imports(rest, acc, schema |> put_error(error(module, reason)))
    end
  end

  # Generate an error when loading module fails
  @spec error(module :: module(), error :: :embedded | :badfile | :nofile | :on_load_failure) ::
          Absinthe.Phase.Error.t()
  defp error(module, reason) do
    %Absinthe.Phase.Error{
      message: "Could not load module `#{module}`. It returned reason: `#{reason}`.",
      phase: __MODULE__
    }
  end
end
