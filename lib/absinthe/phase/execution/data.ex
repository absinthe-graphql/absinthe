defmodule Absinthe.Phase.Execution.Data do

  use Absinthe.Phase

  def run(tree) do
    {:ok, %{data: get_field_data(tree.fields)}}
  end

  def get_data(%{name: name, value: value}) do
    {name, value}
  end
  def get_data(%{name: name, fields: fields}) do
    {name, get_field_data(fields)}
  end

  def get_field_data(fields, acc \\ [])
  def get_field_data([], acc), do: :maps.from_list(acc)
  def get_field_data([{:ok, field} | fields], acc) do
    get_field_data(fields, [get_data(field) | acc])
  end
  def get_field_data([_ | fields], acc) do
    get_field_data(fields, acc)
  end
end
