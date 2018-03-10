defmodule Absinthe.Phase.Document.Validation.UniqueArgumentNames do
  @moduledoc false

  # Validates document to ensure that all arguments for a field or directive
  # have unique names.

  alias Absinthe.{Blueprint, Phase}

  use Absinthe.Phase
  use Absinthe.Phase.Validation

  @doc """
  Run the validation.
  """
  @spec run(Blueprint.t(), Keyword.t()) :: Phase.result_t()
  def run(input, _options \\ []) do
    result = Blueprint.prewalk(input, &handle_node/1)
    {:ok, result}
  end

  @argument_hosts [
    Blueprint.Document.Field,
    Blueprint.Directive
  ]

  # Find fields and directives to check arguments
  @spec handle_node(Blueprint.node_t()) :: Blueprint.node_t()
  defp handle_node(%argument_host{} = node) when argument_host in @argument_hosts do
    arguments = Enum.map(node.arguments, &process(&1, node.arguments))
    %{node | arguments: arguments}
  end

  defp handle_node(node) do
    node
  end

  # Check an argument, finding any duplicates
  @spec process(Blueprint.Input.Argument.t(), [Blueprint.Input.Argument.t()]) ::
          Blueprint.Input.Argument.t()
  defp process(argument, arguments) do
    check_duplicates(argument, Enum.filter(arguments, &(&1.name == argument.name)))
  end

  # Add flags and errors if necessary for each argument.
  @spec check_duplicates(Blueprint.Input.Argument.t(), [Blueprint.Input.Argument.t()]) ::
          Blueprint.Input.Argument.t()
  defp check_duplicates(argument, [_single]) do
    argument
  end

  defp check_duplicates(argument, _multiple) do
    argument
    |> flag_invalid(:duplicate_name)
    |> put_error(error(argument))
  end

  # Generate an error for a duplicate argument.
  @spec error(Blueprint.Input.Argument.t()) :: Phase.Error.t()
  defp error(node) do
    %Phase.Error{
      phase: __MODULE__,
      message: error_message(),
      locations: [node.source_location]
    }
  end

  @doc """
  Generate the error message.
  """
  @spec error_message :: String.t()
  def error_message do
    "Duplicate argument name."
  end
end
