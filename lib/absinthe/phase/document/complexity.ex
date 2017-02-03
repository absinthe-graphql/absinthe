defmodule Absinthe.Phase.Document.Complexity do
  @moduledoc false

  # Analyses document complexity.

  alias Absinthe.{Blueprint, Phase}

  use Absinthe.Phase

  @default_complexity 1

  @doc """
  Run complexity analysis.
  """
  @spec run(Blueprint.t, Keyword.t) :: Phase.result_t
  def run(input, options \\ []) do
    %{operations: ops} = result = Blueprint.postwalk(input, &handle_node/1)
    complexity = sum_complexity(ops)
    max = Keyword.get(options, :max_complexity, :infinity)
    if complexity > max do
      {:error, "complexity is #{complexity}, which is above maximum #{max}"}
    else
      {:ok, result}
    end
  end

  def handle_node(%Blueprint.Document.Field{fields: fields,
                                            argument_data: args,
                                            schema_node: schema_node} = node) do
    complexity = field_complexity(schema_node, args, sum_complexity(fields))
    %{node | complexity: complexity}
  end
  def handle_node(%Blueprint.Document.Operation{fields: fields} = node) do
    %{node | complexity: sum_complexity(fields)}
  end
  def handle_node(node) do
    node
  end

  defp field_complexity(%{complexity: nil}, _, child_complexity) do
    @default_complexity + child_complexity
  end
  defp field_complexity(%{complexity: complexity}, arg, child_complexity)
       when is_function(complexity, 2) do
    complexity.(arg, child_complexity)
  end
  defp field_complexity(%{complexity: {mod, fun}}, arg, child_complexity) do
    apply(mod, fun, [arg, child_complexity])
  end

  defp sum_complexity(fields) do
    Enum.reduce(fields, 0, &sum_complexity/2)
  end

  defp sum_complexity(%{complexity: complexity}, acc) do
    complexity+acc
  end
end
