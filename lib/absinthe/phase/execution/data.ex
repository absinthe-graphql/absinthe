defmodule Absinthe.Phase.Execution.Data do

  @moduledoc """
  Produces data fit for external encoding from annotated value tree
  """

  use Absinthe.Phase

  def run(tree) do
    {:ok, %{data: get_field_data(tree.fields)}}
  end

  #Leaf
  def get_data(%{value: value}), do: value
  #Object
  def get_data(%{fields: fields}), do: get_field_data(fields)
  #List
  def get_data(%{values: values}) do
    Enum.filter_map(values,
      &match?({:ok, _}, &1),
      fn {:ok, item} -> get_data(item) end
    )
  end

  def get_field_data(fields, acc \\ [])
  def get_field_data([], acc), do: :maps.from_list(acc)
  def get_field_data([{:ok, field} | fields], acc) do
    get_field_data(fields, [{field.name, get_data(field)} | acc])
  end
  def get_field_data([_ | fields], acc) do
    get_field_data(fields, acc)
  end
end
