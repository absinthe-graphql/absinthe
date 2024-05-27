defmodule Absinthe.Phase.Schema.DirectiveImports do
  @moduledoc false

  use Absinthe.Phase
  alias Absinthe.Blueprint

  alias Absinthe.Blueprint.Schema

  def run(blueprint, opts) do
    blueprint = Blueprint.prewalk(blueprint, &handle_imports(&1, opts))
    {:ok, blueprint}
  end

  def handle_imports(%Schema.SchemaDefinition{} = schema, opts) do
    default_imports = Keyword.get(opts, :directive_imports, [])

    {directives, schema} =
      do_imports(
        default_imports ++ schema.directive_imports,
        schema.directive_definitions,
        schema
      )

    {:halt, %{schema | directive_definitions: directives}}
  end

  def handle_imports(node, _opts), do: node

  defp do_imports([], types, schema) do
    {types, schema}
  end

  defp do_imports([{module, opts} | rest], acc, schema) do
    case ensure_compiled(module) do
      {:module, module} ->
        [other_def] = module.__absinthe_blueprint__().schema_definitions

        rejections = MapSet.new(Keyword.get(opts, :except, []))

        types = Enum.reject(other_def.directive_definitions, &(&1.identifier in rejections))

        types =
          case Keyword.fetch(opts, :only) do
            {:ok, selections} ->
              Enum.filter(types, &(&1.identifier in selections))

            _ ->
              types
          end

        do_imports(other_def.directive_imports ++ rest, types ++ acc, schema)

      {:error, reason} ->
        do_imports(rest, acc, schema |> put_error(error(module, reason)))
    end
  end

  # Elixir v1.12 includes a Code.ensure_compiled!/1 that tells
  # the compiler it should only continue if the module is available.
  # This gives the Elixir compiler more information to address
  # deadlocks.
  # TODO: Remove the else clause once we require Elixir v1.12+.
  @compile {:no_warn_undefined, {Code, :ensure_compiled!, 1}}
  @dialyzer {:nowarn_function, [ensure_compiled: 1]}
  defp ensure_compiled(module) do
    if function_exported?(Code, :ensure_compiled!, 1) do
      {:module, Code.ensure_compiled!(module)}
    else
      Code.ensure_compiled(module)
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
