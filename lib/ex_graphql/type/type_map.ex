defmodule ExGraphQL.Type.TypeMap do

  alias ExGraphQL.Type

  def build(types) do
    case build(types, %{}) do
      {:error, _} = err -> err
      result -> {:ok, result}
    end
  end

  defp build([], acc) do
    acc
  end
  defp build([nil | rest], acc) do
    build(rest, acc)
  end
  defp build([type | rest], acc) do
    cond do
      Type.wrapped?(type) -> build([ExGraphQL.Type.unwrap(type) | rest], acc)
      true -> do_build(type, rest, acc)
    end
  end

  defp do_build(type, rest, acc) do
    case acc |> Map.get(type.name) do
      nil -> build(deep_types(type) ++ rest, acc |> Map.put(type.name, type))
      value -> {:error, "Schema must contain unique named types but contains multiple types named \"#{value}\"."}
    end
  end

  @doc "Extract deeper types "
  @spec deep_types(Type.t) :: [Type.t]
  defp deep_types(%{__struct__: Type.Union} = type) do
    Type.possible_types(type)
  end
  defp deep_types(%{__struct__: Type.Interface} = type) do
    Type.possible_types(type)
  end

end
