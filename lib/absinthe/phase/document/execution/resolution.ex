defmodule Absinthe.Phase.Document.Execution.Resolution do
  @moduledoc """
  Runs resolution functions in a new blueprint.

  While this phase starts with a blueprint, it returns an annotated value tree.
  """

  alias Absinthe.Blueprint.Document
  alias Absinthe.Phase.Document.Execution
  alias Absinthe.{Type, Schema}

  use Absinthe.Phase

  # Assumes the blueprint has a schema
  def run(blueprint, selected_operation, context \\ %{}, root_value \\ %{}) do
    blueprint.operations
    |> hd
    |> resolve_operation(%Absinthe.Execution.Field{context: context, root_value: root_value, schema: blueprint.schema}, root_value)
  end

  def resolve_operation(operation, info, source) do
    {:ok, %Execution.ResultObject{
      blueprint_node: nil,
      name: operation.name,
      fields: resolve_fields(operation.fields, info, source),
    }}
  end

  defp filter_valid_arguments(arguments) do
    arguments
    |> Enum.reject(&Enum.any?(&1.errors))
    |> Map.new(fn arg ->
      {arg.schema_node.__reference__.identifier, arg.data_value}
    end)
  end

  def resolve_field(field, info, source) do
    resolution_function = field.schema_node.resolve || fn _, _ ->
      {:ok, Map.get(source, field.schema_node.__reference__.identifier)}
    end

    case :invalid in field.flags do
      false ->
        field.arguments
        |> filter_valid_arguments
        |> resolution_function.(%{info | source: source})
        |> case do
          {:ok, result} ->
            full_type = Type.expand(field.schema_node.type, info.schema)
            walk_result(result, field, full_type, info)
          {:error, msg} ->
            {:error, %{message: msg}}
          other ->
            raise """
            Resolution function did not return `{:ok, val}` or `{:error, reason}`
            Resolving field: #{field.name}
            Resolving on: #{inspect source}
            Got: #{inspect other}
            """
        end
      true ->
        {:error, %{message: "Field has invalid arguments"}}
    end
  end

  @doc """
  Handle the result of a resolution function
  """
  ## Limitations
  # - No non null checking
  # -

  ## Leaf nodes

  def walk_result(nil, bp, _, _) do
    {:ok, %Execution.Result{
      # blueprint_node: bp,
      name: bp.alias || bp.name,
      value: nil
    }}
  end
  # Resolve item of type scalar
  def walk_result(item, bp, %Type.Scalar{} = schema_type, _) do
    {:ok, %Execution.Result{
      # blueprint_node: bp,
      name: bp.alias || bp.name,
      value: Type.Scalar.serialize(schema_type, item)
    }}
  end
  # Resolve Enum type
  def walk_result(item, bp, %Type.Enum{} = schema_type, info) do
    {:ok, %Execution.Result{
      # blueprint_node: bp,
      name: bp.alias || bp.name,
      value: Type.Enum.serialize!(schema_type, item)
    }}
  end

  def walk_result(item, bp, %Type.Object{} = type, info) do
    {:ok, %Execution.ResultObject{
      # blueprint_node: bp,
      name: bp.alias || bp.name,
      fields: resolve_fields(bp.fields, info, item),
    }}
  end

  def walk_result(items, bp, %Type.List{of_type: inner_type}, info) do
    values =
      items
      |> List.wrap # if it's just a single item we're supposed to wrap it in a list anyway.
      |> walk_results(bp, inner_type, info)

    {:ok, %Execution.ResultList{name: bp.name, values: values}}
  end

  def walk_result(nil, _, %Type.NonNull{}, _) do
    # We may want to raise here because this is a programmer error in some sense
    # not a graphql user error.
    # TODO: handle default value. Are there even default values on output types?
    {:error, "Supposed to be non nil"}
  end

  def walk_result(val, bp, %Type.NonNull{of_type: inner_type}, info) do
    walk_result(val, bp, inner_type, info)
  end
  def walk_result(a, b, c, d) do
    IO.inspect [
      a: a,
      b: b,
      c: c,
      d: d
    ]
    raise "dead"
  end

  defp walk_results(items, bp, inner_type, info, acc \\ [])
  defp walk_results([], _, _, _, acc), do: :lists.reverse(acc)
  defp walk_results([item | items], bp, inner_type, info, acc) do
    result = walk_result(item, bp, inner_type, info)
    walk_results(items, bp, inner_type, info, [result | acc])
  end

  defp resolve_fields(fields, info, item, acc \\ [])
  defp resolve_fields([], _, _, acc), do: :lists.reverse(acc)
  defp resolve_fields([%{schema_node: nil} | fields], info, item, acc) do
    resolve_fields(fields, info, item, acc)
  end
  defp resolve_fields([field | fields], info, item, acc) do
    result = resolve_field(field, info, item)
    resolve_fields(fields, info, item, [result | acc])
  end

end
