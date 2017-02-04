defmodule Absinthe.Phase.Document.Complexity do
  @moduledoc false

  # Analyses document complexity.

  alias Absinthe.{Blueprint, Phase, Schema}

  use Absinthe.Phase

  @default_complexity 1

  defmodule Info do

    @enforce_keys [:context, :root_value, :schema, :definition]
    defstruct [:context, :root_value, :schema, :definition]

    @type t :: %__MODULE__{
      context: map,
      root_value: any,
      schema: Schema.t,
      definition: Blueprint.node_t
    }

  end

  @doc """
  Run complexity analysis.
  """
  @spec run(Blueprint.t, Keyword.t) :: Phase.result_t
  def run(input, options \\ []) do
    info_data = info_boilerplate(input, options)
    %{operations: ops} = result = Blueprint.postwalk(input, &handle_node(&1, info_data))
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
                                            schema_node: schema_node} = node, info_data) do
    complexity = field_complexity(schema_node, args, sum_complexity(fields), info_data, node)
    %{node | complexity: complexity}
  end
  def handle_node(%Blueprint.Document.Operation{fields: fields} = node, _) do
    %{node | complexity: sum_complexity(fields)}
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
    info = struct(Info, Map.put(info_data, :definition, node))
    complexity.(arg, child_complexity, info)
  end
  defp field_complexity(%{complexity: {mod, fun}}, arg, child_complexity, _, _) do
    apply(mod, fun, [arg, child_complexity])
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
