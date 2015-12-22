defmodule Absinthe.Type.TypeMap do

  alias Absinthe.Type

  def build(%{query: query, mutation: mutation, subscription: subscription} = schema) do
    [query, mutation, subscription]
    |> Enum.reduce(%{}, &reducer/2)
  end

  defp reducer(type, acc) do
    unwrapped = type |> Type.unwrap
    # TODO: Ensure type is valid
    if Type.named?(unwrapped) && Map.get(acc, unwrapped.name) == unwrapped do
      acc
    else
      traverse(unwrapped, acc)
    end
  end

  defp traverse(%{name: name} = type, acc) do
    acc
    |> Map.put(name, type)
    |> accumulate_from_fields(type)
    |> accumulate_from_interfaces(type)
    |> accumulate_from_concrete_types(type)
  end
  defp traverse(type, acc) do
    acc
  end

  defp accumulate_from_fields(acc, type) do
    if Type.fielded?(type) do
      type.fields
      |> Type.unthunk
      |> Map.values
      |> Enum.reduce(acc, fn (field, acc_for_field) ->
        acc_with_field = reducer(field.type, acc_for_field)
        field
        |> Map.get(:args, %{})
        |> Map.values
        |> Enum.reduce(acc_with_field, fn (arg, acc_for_arg) ->
          reducer(arg.type, acc_for_arg)
        end)
      end)
    else
      acc
    end
  end

  defp accumulate_from_interfaces(acc, type) do
    if Type.object_type?(type) do
      type.interfaces
      |> Enum.reduce(acc, &reducer/2)
    else
      acc
    end
  end

  # TODO: Make interface types actually traversable; their `types` field
  # should return the types that implement the interface, but that would mean
  # collecting those types in a separate traversal
  defp accumulate_from_concrete_types(acc, type) do
    if Type.abstract?(type) do
      type.types
      |> Enum.reduce(acc, &reducer/2)
    else
      acc
    end
  end

end
