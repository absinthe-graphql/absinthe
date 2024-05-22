defmodule Absinthe.Phase.Schema.SpecCompliantInt do
  @moduledoc false

  @behaviour Absinthe.Phase
  alias Absinthe.Blueprint

  def pipeline(pipeline) do
    Absinthe.Pipeline.insert_after(
      pipeline,
      Absinthe.Phase.Schema.TypeImports,
      __MODULE__
    )
  end

  @spec run(Blueprint.t(), Keyword.t()) :: {:ok, Blueprint.t()}
  def run(input, _options \\ []) do
    node = Blueprint.prewalk(input, &handle_node/1)
    {:ok, node}
  end

  defp handle_node(%Blueprint.Schema.ScalarTypeDefinition{identifier: :integer}) do
    case ensure_compiled(Absinthe.Type.BuiltIns.SpecCompliantInt) do
      {:module, module} ->
        [types] = module.__absinthe_blueprint__().schema_definitions

        Enum.find(
          types.type_definitions,
          &(&1.identifier == :integer)
        )

      {:error, reason} ->
        raise reason
    end
  end

  defp handle_node(node) do
    node
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
end
