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
    {data, errors} = get_field_data(tree.fields, [])
    %{data: data, errors: errors}
  end

  defp clean(%{data: data} = result) when map_size(data) == 0 do
    Map.delete(result, :data)
  end
  defp clean(%{errors: []} = result) do
    Map.delete(result, :errors)
  end

  # Leaf
  def get_data(%{value: value}, errors), do: {value, errors}

  # Object
  def get_data(%{fields: fields}, errors), do: get_field_data(fields, errors)

  # List
  def get_data(%{values: values}, errors), do: get_list_data(values, errors)

  def get_list_data(fields, errors, acc \\ [])
  def get_list_data([], errors, acc), do: {:lists.reverse(acc), errors}
  def get_list_data([{:ok, field} | fields], errors, acc) do
    {value, errors} = get_data(field, errors)
    get_list_data(fields, errors, [value | acc])
  end
  def get_list_data([{:error, error} | fields], errors, acc) do
    get_list_data(fields, List.wrap(error) ++ errors, acc)
  end

  def get_field_data(fields, errors, acc \\ [])
  def get_field_data([], errors, acc), do: {:maps.from_list(acc), errors}
  def get_field_data([{:ok, field} | fields], errors, acc) do
    {value, errors} = get_data(field, errors)
    get_field_data(fields, errors, [{field.name, value} | acc])
  end
  def get_field_data([{:error, error} | fields], errors, acc) do
    get_field_data(fields, List.wrap(error) ++ errors, acc)
  end
end
