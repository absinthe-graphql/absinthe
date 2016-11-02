defmodule Absinthe.Phase.Document.CascadeInvalid do
  # Ensure any nodes whose children are invalid that need to be made
  # invalid is marked invalid.

  @moduledoc false

  use Absinthe.Phase

  alias Absinthe.Blueprint

  @spec run(Blueprint.t, Keyword.t) :: {:ok, Blueprint.t}
  def run(input, _options \\ []) do
    result = Blueprint.update_current(input, &process/1)
    {:ok, result}
  end

  defp process(operation) do
    Blueprint.prewalk(operation, &handle_node/1)
  end

  defp handle_node(%Blueprint.Document.Field{} = node) do
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
  defp handle_node(node) do
    node
  end

end
