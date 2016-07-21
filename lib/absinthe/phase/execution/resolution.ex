defmodule Absinthe.Phase.Execution.Resolution do
  @moduledoc """
  Runs resolution functions in a new blueprint.

  While this phase starts with a blueprint, it returns an annotated value tree.
  """

  alias Absinthe.Blueprint.Document
  alias Absinthe.Phase.Execution
  alias Absinthe.{Type, Schema}

  use Absinthe.Phase

  # Assumes the blueprint has a schema
  def run(blueprint, selected_operation, context \\ %{}, root_value \\ %{}) do
    blueprint.operations
    |> hd
    |> resolve_operation(%Absinthe.Execution.Field{context: context, root_value: root_value, schema: blueprint.schema}, root_value)
  end

  def resolve_operation(operation, info, source) do
    {:ok, %Execution.Node{
      blueprint_node: nil,
      name: operation.name,
      fields: Enum.map(operation.fields, &resolve_field(&1, info, source)),
    }}
  end

  defp filter_valid_arguments(arguments) do
    Map.new(arguments, fn arg ->
      {arg.schema_node.__reference__.identifier, arg.data_value}
    end)
  end

  def resolve_field(%{schema_node: nil} = node, _, _) do
    IO.puts "NO schema node for: #{inspect node}"
    # TODO: real error handling
    {:error, "field doesn't exist in schema"}
  end
  def resolve_field(field, info, source) do
    resolution_function = field.schema_node.resolve || fn _, _ ->
      Map.fetch(source, field.schema_node.__reference__.identifier)
    end

    field.arguments
    |> filter_valid_arguments
    |> resolution_function.(%{info | source: source})
    |> case do
      {:ok, result} ->
        inner_type = Schema.lookup_type(info.schema, field.schema_node.type)
        walk_result(result, field, inner_type, info)
      other ->
        other
    end
  end

  @doc """
  Handle the result of a resolution function
  """
  ## Limitations
  # - No non null checking
  # -

  ## Leaf nodes

  # Resolve item of type scalar
  def walk_result(item, bp, %Type.Scalar{} = schema_type, _) do
    {:ok, %Execution.Leaf{
      # blueprint_node: bp,
      name: bp.alias || bp.name,
      value: Type.Scalar.serialize(schema_type, item)
    }}
  end
  # Resolve Enum type
  def walk_result(item, bp, %Type.Enum{} = schema_type, info) do
    {:ok, %Execution.Leaf{
      # blueprint_node: bp,
      name: bp.alias || bp.name,
      value: Type.Enum.serialize!(schema_type, item)
    }}
  end

  def walk_result(item, bp, %Type.Object{} = type, info) do
    {:ok, %Execution.Node{
      # blueprint_node: bp,
      name: bp.alias || bp.name,
      fields: Enum.map(bp.fields, &resolve_field(&1, info, item)),
    }}
  end

end
