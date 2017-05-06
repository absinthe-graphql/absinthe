defmodule Absinthe.Phase.Document.Validation.VariablesOfCorrectType do
  @moduledoc false

  # Validates document to ensure that all arguments are of the correct type.

  alias Absinthe.{Blueprint, Phase, Type}
  alias Absinthe.Blueprint.Input

  use Absinthe.Phase

  @doc """
  Run this validation.
  """
  @spec run(Blueprint.t, Keyword.t) :: Phase.result_t
  def run(input, _options \\ []) do
    case Blueprint.current_operation(input) do
      nil ->
        {:ok, input}

      op ->
        fragment_uses = MapSet.new(op.fragment_uses, &(&1.name))
        var_map = Map.new(op.variable_definitions, &{&1.name, &1})

        result = Blueprint.prewalk(input, &handle_node(&1, var_map, fragment_uses))

        {:ok, result}
    end
  end

  defp handle_node(%Blueprint.Document.Fragment.Named{name: name} = node, _, fragment_uses) do
    case MapSet.member?(fragment_uses, name) do
      true -> node
      false -> {:halt, node}
    end
  end
  defp handle_node(%{input_value: %{schema_node: nil}} = node, _, _) do
    {:halt, node}
  end
  defp handle_node(%{input_value: %{schema_node: schema_node, normalized: %Input.Variable{name: name}}} = node, variables, _fragment_uses) do
    %{identifier: target_identifier} = Type.unwrap(schema_node)

    node = case Map.fetch(variables, name) do
      :error ->
        node
      {:ok, %{schema_node: var_schema_node}} ->
        case Type.unwrap(var_schema_node) do
          %{identifier: ^target_identifier} ->
            node
          _ ->
          node |> flag_invalid
        end
    end

    {:halt, node}
  end
  defp handle_node(node, _, _) do
    node
  end

end
