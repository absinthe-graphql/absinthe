defmodule Absinthe.Phase.Document.CascadeInvalid do
  @moduledoc """
  Ensure any nodes whose children are invalid that need to be made
  invalid is marked invalid.
  """

  use Absinthe.Phase

  alias Absinthe.Blueprint

  @spec run(Blueprint.t) :: {:ok, Blueprint.t}
  def run(input) do
    result = Blueprint.update_current(input, &process(&1, input.schema))
    {:ok, result}
  end

  defp process(operation, schema) do
    Blueprint.prewalk(operation, &handle_node(&1, schema))
  end

  defp handle_node(%Blueprint.Document.Field{} = node, schema) do
    node = if any_invalid?(node.arguments) do
      node |> flag_invalid(:bad_arguments)
    else
      node
    end
    node = if any_invalid?(node.directives) do
      node |> flag_invalid(:bad_directives)
    else
      node
    end
    node
  end
  defp handle_node(node, _) do
    node
  end

end
