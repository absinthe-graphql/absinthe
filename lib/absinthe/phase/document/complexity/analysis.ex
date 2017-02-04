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
    max = Keyword.get(options, :max_complexity, :infinity)
    fun = &handle_node(&1, info_data, max)
    {:ok, Blueprint.update_current(input, &Blueprint.postwalk(&1, fun))}
  end

  def handle_node(%Blueprint.Document.Field{fields: fields,
                                            argument_data: args,
                                            schema_node: schema_node} = node, info_data, max) do
    child_complexity = sum_complexity(fields)
    complexity = field_complexity(schema_node, args, child_complexity, info_data, node)
    check_complexity(%{node | complexity: complexity}, complexity, max)
  end
  def handle_node(%Blueprint.Document.Operation{complexity: nil, fields: fields} = node, _, max) do
    complexity = sum_complexity(fields)
    check_complexity(%{node | complexity: complexity}, complexity, max)
  end
  def handle_node(node, _, _) do
    node
  end

  defp field_complexity(%{complexity: nil}, _, child_complexity, _, _) do
    @default_complexity + child_complexity
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

  defp check_complexity(node, complexity, max) when complexity > max do
    node
    |> flag_invalid(:too_complex)
    |> put_error(error(node, complexity, max))
  end
  defp check_complexity(node, _, _) do
    node
  end

  defp error(%{name: name, source_location: location}, complexity, max) do
    Phase.Error.new(
      __MODULE__,
      error_message(name, complexity, max),
      location: location
    )
  end

  def error_message(name, complexity, max) do
    "#{name} is too complex: complexity is #{complexity} and maximum is #{max}"
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
