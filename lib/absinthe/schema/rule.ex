defmodule Absinthe.Schema.Rule do

  alias __MODULE__

  defmacro __using__(_opts) do
    quote do
      @behaviour unquote(__MODULE__)

      def report(location, data) do
        %{
          rule: __MODULE__,
          location: location,
          data: data
        }
      end

    end
  end

  @callback check(Absithe.Schema.t) :: [Absinthe.Error.Detail.t]
  @callback explanation(Absithe.Error.Detail.t) :: binary

  @rules [
    Rule.TypeNamesAreReserved
  ]

  @spec check(Absinthe.Schema.t) :: [Absinthe.Error.Detail.t]
  def check(schema) do
    Enum.flat_map(@rules, &(&1.check(schema)))
  end

end
