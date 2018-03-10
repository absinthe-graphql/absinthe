defmodule Absinthe.Phase.Document.CurrentOperation do
  @moduledoc false

  # Selects the current operation.
  #
  # - If an operation name is given, the matching operation is marked as current.
  # - If no operation name is provided and the there is only one operation,
  #   it is set as current.
  #
  # Note that no validation occurs in this phase.

  use Absinthe.Phase
  alias Absinthe.Blueprint

  @spec run(Blueprint.t(), Keyword.t()) :: {:ok, Blueprint.t()}
  def run(input, options \\ []) do
    operations = process(input.operations, Map.new(options))
    result = %{input | operations: operations}
    {:ok, result}
  end

  defp process([op], %{operation_name: nil}) do
    [%{op | current: true}]
  end

  defp process([%{name: name} = op], %{operation_name: name}) do
    [%{op | current: true}]
  end

  defp process(ops, %{operation_name: name}) do
    Enum.map(ops, fn
      %{name: ^name} = op ->
        %{op | current: true}

      op ->
        op
    end)
  end

  defp process(ops, _) do
    ops
  end
end
