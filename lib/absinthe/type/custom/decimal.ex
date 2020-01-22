if Code.ensure_loaded?(Decimal) do
  defmodule Absinthe.Type.Custom.Decimal do
    @moduledoc false

    defdelegate serialize(value), to: Decimal, as: :to_string

    alias Absinthe.Blueprint.Input

    @spec parse(any) :: {:ok, Decimal.t()} | {:ok, nil} | :error
    def parse(%Input.String{value: value}) when is_binary(value) do
      case Decimal.parse(value) do
        {:ok, decimal} -> {:ok, decimal}
        _ -> :error
      end
    end

    def parse(%Input.Float{value: value}) when is_float(value) do
      decimal = Decimal.from_float(value)
      if Decimal.nan?(decimal), do: :error, else: {:ok, decimal}
    end

    def parse(%Input.Integer{value: value}) when is_integer(value) do
      decimal = Decimal.new(value)
      if Decimal.nan?(decimal), do: :error, else: {:ok, decimal}
    end

    def parse(%Input.Null{}) do
      {:ok, nil}
    end

    def parse(_) do
      :error
    end
  end
else
  defmodule Absinthe.Type.Custom.Decimal do
    @moduledoc false

    @spec parse(any) :: :error
    def parse(_), do: :error

    @spec serialize(any) :: nil
    def serialize(_), do: nil
  end
end
