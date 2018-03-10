defmodule Absinthe.Schema.Rule.TypeNamesAreValid do
  use Absinthe.Schema.Rule

  alias Absinthe.Schema
  alias Absinthe.Type

  @moduledoc false

  @description """
  Types must exist if referenced.
  """

  def explanation(%{data: %{identifier: identifier, parent: parent}}) do
    artifact_name = String.capitalize(parent.name)

    """
    #{artifact_name} #{inspect(identifier)} is not defined in your schema.

    #{@description}
    """
  end

  def check(schema) do
    Enum.reduce(schema.__absinthe_types__, [], fn {identifier, name}, acc ->
      schema
      |> Schema.lookup_type(identifier)
      |> case do
        nil -> Schema.lookup_type(schema, name)
        val -> val
      end
      |> check_type(acc, schema)
    end)
  end

  defp check_type(type, acc, schema) do
    check_type(type, type, acc, schema)
  end

  # I could do this in fewer clauses by simply matching on the inner properties
  # that we care about, but by doing it this way you can easily scan the list
  # and compare it to the modules in absinthe/type/*.ex to see it's complete.
  defp check_type(identifier, parent, acc, schema) when is_atom(identifier) do
    case schema.__absinthe_type__(identifier) do
      nil ->
        data = %{parent: parent, identifier: identifier}
        [report(parent.__reference__.location, data) | acc]

      _ ->
        acc
    end
  end

  defp check_type(%Type.Argument{} = arg, _, acc, schema) do
    check_type(arg.type, arg, acc, schema)
  end

  defp check_type(%Type.Directive{} = type, _, acc, schema) do
    type.args
    |> Map.values()
    |> Enum.reduce(acc, &check_type(&1, type, &2, schema))
  end

  defp check_type(%Type.Enum{} = type, _, acc, schema) do
    type.values
    |> Map.values()
    |> Enum.reduce(acc, &check_type(&1, type, &2, schema))
  end

  defp check_type(%Type.Enum.Value{}, _, acc, _schema) do
    acc
  end

  defp check_type(%Type.Field{} = field, _, acc, schema) do
    acc =
      field.args
      |> Map.values()
      |> Enum.reduce(acc, &check_type(&1, field, &2, schema))

    check_type(field.type, field, acc, schema)
  end

  defp check_type(%Type.InputObject{} = object, _, acc, schema) do
    object.fields
    |> Map.values()
    |> Enum.reduce(acc, &check_type(&1, object, &2, schema))
  end

  defp check_type(%Type.Interface{} = interface, _, acc, schema) do
    interface.fields
    |> Map.values()
    |> Enum.reduce(acc, &check_type(&1, interface, &2, schema))
  end

  defp check_type(%Type.List{of_type: inner_type}, parent, acc, schema) do
    check_type(inner_type, parent, acc, schema)
  end

  defp check_type(%Type.NonNull{of_type: inner_type}, parent, acc, schema) do
    check_type(inner_type, parent, acc, schema)
  end

  defp check_type(%Type.Object{} = object, _, acc, schema) do
    object.fields
    |> Map.values()
    |> Enum.reduce(acc, &check_type(&1, object, &2, schema))
  end

  defp check_type(%Type.Reference{} = ref, _, acc, schema) do
    check_type(ref.identifier, ref, acc, schema)
  end

  defp check_type(%Type.Scalar{}, _, acc, _schema) do
    acc
  end

  defp check_type(%Type.Union{} = union, _, acc, schema) do
    union.types
    |> Enum.reduce(acc, &check_type(&1, union, &2, schema))
  end
end
