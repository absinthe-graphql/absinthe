defmodule Absinthe.Phase.Execution.Resolution do
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

  def resolve_field(field, info, source) do
    resolution_function = field.schema_node.resolve || fn _, _ ->
      Map.fetch(source, field.schema_node.__reference__.identifier)
    end

    case resolution_function.(valid_arguments(field.arguments), %{info | source: source}) do
      {:ok, result} ->
        inner_type = Schema.lookup_type(info.schema, field.schema_node.type)
        resolve_item(result, field, inner_type, info)
      other ->
        other
    end
  end

  defp valid_arguments(arguments) do
    Map.new(arguments, fn arg ->
      {arg.schema_node.__reference__.identifier, arg.data_value}
    end)
  end


  @doc """
  Handle the result of a resolution function
  """
  ## Limitations
  # - No non null checking
  # -

  ## Leaf nodes

  # Resolve item of type scalar
  def resolve_item(item, bp, %Type.Scalar{} = schema_type, _) do
    {:ok, %Execution.Leaf{
      # blueprint_node: bp,
      name: bp.name,
      value: Type.Scalar.serialize(schema_type, item)
    }}
  end
  # Resolve Enum type
  def resolve_item(item, bp, %Type.Enum{} = schema_type, info) do
    {:ok, %Execution.Leaf{
      blueprint_node: bp,
      name: bp.name,
      value: Type.Enum.serialize!(schema_type, item)
    }}
  end

  ## ObjectTypes
  def resolve_item(item, %{schema_node: %Type.Object{} = type} = bp, info) do
    {:ok,
      Enum.map(bp.fields, &resolve_field(&1, info, item))
    }
  end

end
