defmodule Absinthe.Schema.Rule do
  @moduledoc false

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

  @callback check(Absinthe.Schema.t()) :: [Absinthe.Phase.Error.t()]
  @callback explanation(Absinthe.Phase.Error.t()) :: binary

  @type t :: module

  @rules [
    Rule.QueryTypeMustBeObject,
    Rule.TypeNamesAreReserved,
    Rule.TypeNamesAreValid,
    Rule.ObjectInterfacesMustBeValid,
    Rule.ObjectMustImplementInterfaces,
    Rule.InterfacesMustResolveTypes,
    Rule.InputOutputTypesCorrectlyPlaced,
    Rule.DefaultEnumValuePresent
  ]

  @spec check(Absinthe.Schema.t()) :: [Absinthe.Phase.Error.t()]
  def check(schema) do
    Enum.flat_map(@rules, & &1.check(schema))
  end
end
