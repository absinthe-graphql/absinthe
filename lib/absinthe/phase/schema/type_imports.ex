defmodule Absinthe.Phase.Schema.TypeImports do
  @moduledoc false

  use Absinthe.Phase
  alias Absinthe.Blueprint

  alias Absinthe.Blueprint.Schema

  def run(blueprint, opts) do
    blueprint = Blueprint.prewalk(blueprint, &handle_imports(&1, opts))
    {:ok, blueprint}
  end

  def handle_imports(%Schema.SchemaDefinition{} = schema, opts) do
    default_imports = Keyword.get(opts, :type_imports, [])

    {types, schema} =
      do_imports(
        default_imports ++ schema.imports,
        schema.type_definitions,
        schema
      )

    schema = %{schema | type_definitions: types}

    {:halt, %{schema | type_definitions: types}}
  end

  def handle_imports(node, _), do: node

  defp do_imports([], types, schema) do
    {types, schema}
  end

  defp do_imports([{module, opts} | rest], types_acc, schema) do
    case ensure_compiled(module) do
      {:module, module} ->
        [other_def] = module.__absinthe_blueprint__().schema_definitions

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

        do_imports(
          other_def.imports ++ rest,
          types ++ types_acc,
          schema
        )

      {:error, reason} ->
        do_imports(
          rest,
          types_acc,
          schema |> put_error(error(module, reason))
        )
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
  catch
    # Code.ensure_compiled! in Elixir >1.12 raises an ArgumentError if it is unable to find the module with message similar to
    # "could not load module <module> due to reason <reason>"
    # where reason is an atom :embedded | :badfile | :nofile | :on_load_failure | :unavailable
    _, %ArgumentError{message: message} ->
      reason = message |> String.split(":") |> List.last()
      {:error, reason}
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
