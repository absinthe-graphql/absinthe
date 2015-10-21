defmodule ExGraphQL.Type.FieldDefinitionMap do

  defmodule ResolutionError do
    defexception message: "resolution failed"
  end

  def resolve(fields) when is_map(fields), do: {:ok, fields}
  def resolve(fields) when is_function(fields) do
    case fields.() do
      %{} = result -> {:ok, result}
      _ -> :error
    end
  end

  def get(fields, field_name) when is_atom(field_name) do
    case resolve(fields) do
      {:ok, result} -> result |> Map.get(field_name) |> add_name(field_name)
      :error -> raise ResolutionError
    end
  end

  defp add_name(field, name) do
    field |> Map.put(:name, name |> to_string)
  end

end
