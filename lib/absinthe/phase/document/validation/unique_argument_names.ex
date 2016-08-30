defmodule Absinthe.Phase.Document.Validation.UniqueArgumentNames do
  @moduledoc """
  Validates document to ensure that all arguments for a field or directive
  have unique names.
  """

  alias Absinthe.{Blueprint, Phase}

  use Absinthe.Phase
  use Absinthe.Phase.Document.Validation

  @spec run(Blueprint.t) :: Phase.result_t
  def run(input) do
    result = Blueprint.prewalk(input, &handle_node/1)
    {:ok, result}
  end

  @argument_hosts [
    Blueprint.Document.Field,
    Blueprint.Directive
  ]

  defp handle_node(%argument_host{} = node) when argument_host in @argument_hosts do
    arguments = Enum.map(node.arguments, &(process(&1, node.arguments)))
    %{node | arguments: arguments}
    |> inherit_invalid(arguments, :duplicate_arguments)
  end
  defp handle_node(node) do
    node
  end

  defp process(argument, arguments) do
    do_process(argument, Enum.filter(arguments, &(&1.name == argument.name)))
  end

  defp do_process(argument, [_single]) do
    argument
  end
  defp do_process(argument, _multiple) do
    %{
      argument |
      flags: [:invalid, :duplicate_name] ++ argument.flags,
      errors: [error(argument) | argument.errors]
    }
  end

  defp error(node) do
    Phase.Error.new(
      __MODULE__,
      "Duplicate argument name.",
      node.source_location
    )
  end

end
