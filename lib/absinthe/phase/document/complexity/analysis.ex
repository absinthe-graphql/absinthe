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
    if Keyword.get(options, :analyze_complexity, false) do
      do_run(input, options)
    else
      {:ok, input}
    end
  end

  defp do_run(input, options) do
    info_data = info_boilerplate(input, options)
    fun = &handle_node(&1, info_data)
    {:ok, Blueprint.update_current(input, &Blueprint.postwalk(&1, fun))}
  end

  def handle_node(%Blueprint.Document.Field{complexity: nil,
                                            fields: fields,
                                            argument_data: args,
                                            schema_node: schema_node} = node, info_data) do
    child_complexity = sum_complexity(fields)
    case field_complexity(schema_node, args, child_complexity, info_data, node) do
      complexity when is_integer(complexity) and complexity >= 0 ->
        %{node | complexity: complexity}
      other ->
        raise Absinthe.AnalysisError, field_value_error(node, other)
    end
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
  defp field_complexity(%{complexity: complexity}, arg, child_complexity, _, _)
       when is_function(complexity, 2) do
    complexity.(arg, child_complexity)
  end
  defp field_complexity(%{complexity: complexity}, arg, child_complexity, info_data, node)
       when is_function(complexity, 3) do
    info = struct(Complexity, Map.put(info_data, :definition, node))
    complexity.(arg, child_complexity, info)
  end
  defp field_complexity(%{complexity: {mod, fun}}, arg, child_complexity, info_data, node) do
    info = struct(Complexity, Map.put(info_data, :definition, node))
    apply(mod, fun, [arg, child_complexity, info])
  end
  defp field_complexity(%{complexity: complexity}, _, _, _, _) do
    complexity
  end

  defp field_value_error(field, value) do
    """
    Invalid value returned from complexity analyzer.

    Analyzing field:

      #{field.name}

    Defined at:

      #{field.schema_node.__reference__.location.file}:#{field.schema_node.__reference__.location.line}

    Got value:

        #{inspect value}

    The complexity value must be a non negative integer.
    """
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
