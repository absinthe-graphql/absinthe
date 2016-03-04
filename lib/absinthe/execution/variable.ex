defmodule Absinthe.Execution.Variable do
  @moduledoc false
  # Represents an execution variable

  alias Absinthe.{Language, Type}

  defstruct value: nil, type_name: nil

  def build(value, %{name: type_name} = schema_type) do
    with {:ok, value} <- coerce(value, schema_type) do
      {:ok, %__MODULE__{value: value, type_name: type_name}}
    end
  end

  defp coerce(value, %Type.Scalar{parse: parser}) do
    case parser.(value) do
      {:ok, coerced_value} ->
        {:ok, coerced_value}
      :error ->
        {:error, &"Error #{&1}"}
    end
  end

end
