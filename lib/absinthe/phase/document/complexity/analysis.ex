defmodule Absinthe.Phase.Document.Complexity.Analysis do
  @moduledoc false

  # Analyses document complexity.

  alias Absinthe.{Blueprint, Phase, Complexity}

  use Absinthe.Phase

  @default_complexity 1

  @doc """
  Run complexity analysis.
  """
  @spec run(Blueprint.t, Keyword.t) :: Phase.result_t
  def run(input, options \\ []) do
    info_data = info_boilerplate(input, options)
    fun = &handle_node(&1, info_data)
    {:ok, Blueprint.update_current(input, &Blueprint.postwalk(&1, fun))}
  end

  def handle_node(%Blueprint.Document.Field{fields: fields,
                                            argument_data: args,
                                            schema_node: schema_node} = node, info_data) do
    child_complexity = sum_complexity(fields)
    complexity = field_complexity(schema_node, args, child_complexity, info_data, node)
    %{node | complexity: complexity}
  end
  def handle_node(%Blueprint.Document.Operation{complexity: nil, fields: fields} = node, _) do
    complexity = sum_complexity(fields)
    %{node | complexity: complexity}
  end
  def handle_node(node, _) do
    node
  end

  defp field_complexity(%{complexity: nil}, _, child_complexity, _, _) do
    @default_complexity + child_complexity
  end
  defp field_complexity(%{complexity: complexity}, _, _, _, _)
       when is_integer(complexity) and complexity >= 0 do
    complexity
  end
  defp field_complexity(%{complexity: complexity}, arg, child_complexity, _, _)
       when is_function(complexity, 2) do
    complexity.(arg, child_complexity)
  end
  defp field_complexity(%{complexity: complexity}, arg, child_complexity, info_data, node)
       when is_function(complexity, 3) do
    info = struct(Complexity, Map.put(info_data, :definition, node))
    complexity.(arg, child_complexity, info)
  end
  defp field_complexity(%{complexity: {mod, fun}}, arg, child_complexity, info_data, _) do
    info = struct(Complexity, Map.put(info_data, :definition, node))
    apply(mod, fun, [arg, child_complexity, info])
  end

  defp sum_complexity(fields) do
    Enum.reduce(fields, 0, &sum_complexity/2)
  end

  defp sum_complexity(%{complexity: complexity}, acc) do
    complexity + acc
  end

  # Execution context data that's common to all fields
  defp info_boilerplate(bp_root, options) do
    %{
      context: Keyword.get(options, :context, %{}),
      root_value: Keyword.get(options, :root_value, %{}),
      schema: bp_root.schema
    }
  end

end
