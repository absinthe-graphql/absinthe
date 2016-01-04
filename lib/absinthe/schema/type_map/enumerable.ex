defimpl Enumerable, for: Absinthe.Schema.TypeMap do

  # Stolen ruthlessly from the Map implementation

  def reduce(type_map, acc, fun) do
    do_reduce(:maps.to_list(type_map.by_identifier), acc, fun)
  end

  defp do_reduce(_,     {:halt, acc}, _fun),   do: {:halted, acc}
  defp do_reduce(list,  {:suspend, acc}, fun), do: {:suspended, acc, &do_reduce(list, &1, fun)}
  defp do_reduce([],    {:cont, acc}, _fun),   do: {:done, acc}
  defp do_reduce([h|t], {:cont, acc}, fun),    do: do_reduce(t, fun.(h, acc), fun)

  def member?(type_map, {key, value}) do
    {:ok, match?({:ok, ^value}, :maps.find(key, type_map.by_identifier))}
  end

  def member?(_type_map, _other) do
    {:ok, false}
  end

  def count(type_map) do
    {:ok, map_size(type_map.by_identifier)}
  end
end
