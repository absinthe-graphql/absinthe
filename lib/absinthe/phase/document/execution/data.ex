defmodule Absinthe.Phase.Document.Execution.Data do

  @moduledoc """
  Produces data fit for external encoding from annotated value tree
  """

  alias Absinthe.Blueprint
  use Absinthe.Phase

  def run(blueprint) do
    result = blueprint
    |> Blueprint.current_operation
    |> process
    |> clean
    {:ok, result}
  end

  defp process(%Blueprint.Document.Operation{resolution: tree}) do
    {data, errors} = field_data(tree.fields, [])
    %{data: data, errors: errors}
  end

  defp clean(%{data: data} = result) when map_size(data) == 0 do
    Map.delete(result, :data)
  end
  defp clean(%{errors: []} = result) do
    Map.delete(result, :errors)
  end

  # Leaf
  defp data(%{value: value}, errors), do: {value, errors}

  # Object
  defp data(%{fields: fields}, errors), do: field_data(fields, errors)

  # List
  defp data(%{values: values}, errors), do: list_data(values, errors)

  defp list_data(fields, errors, acc \\ [])
  defp list_data([], errors, acc), do: {:lists.reverse(acc), errors}
  defp list_data([{:ok, field} | fields], errors, acc) do
    {value, errors} = data(field, errors)
    list_data(fields, errors, [value | acc])
  end
  defp list_data([{:error, error} | fields], errors, acc) do
    list_data(fields, List.wrap(error) ++ errors, acc)
  end

  defp field_data(fields, errors, acc \\ [])
  defp field_data([], errors, acc), do: {:maps.from_list(acc), errors}
  defp field_data([{:ok, field} | fields], errors, acc) do
    {value, errors} = data(field, errors)
    field_data(fields, errors, [{field_name(field), value} | acc])
  end
  defp field_data([{:error, error} | fields], errors, acc) do
    field_data(fields, List.wrap(error) ++ errors, acc)
  end

  defp field_name(%{emitter: %{alias: nil, name: name}}), do: name
  defp field_name(%{emitter: %{alias: name}}), do: name
  defp field_name(%{emitter: %{name: name}}), do: name
end
