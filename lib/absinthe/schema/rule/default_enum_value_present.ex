defmodule Absinthe.Schema.Rule.DefaultEnumValuePresent do
  use Absinthe.Schema.Rule

  alias Absinthe.{Schema, Type}
  require IEx

  @moduledoc false

  def explanation(%{data: %{default_value: default_value, type: type, value_list: value_list}}) do
    """
    The default_value for an enum must be present in the enum values.

    Could not use default value of "#{default_value}" for #{inspect(type)}.

    Valid values are:
    #{value_list}
    """
  end

  def check(schema) do
    Schema.types(schema)
    |> Enum.flat_map(&check_type(schema, &1))
  end

  defp check_type(schema, %Type.Object{fields: fields}) when not is_nil(fields) do
    Enum.flat_map(fields, &check_field(schema, &1))
  end

  defp check_type(_schema, _type), do: []

  defp check_field(schema, {_name, %{args: args}}) when not is_nil(args) do
    Enum.flat_map(args, &check_args(schema, &1))
  end

  defp check_field(_schema, _type), do: []

  defp check_args(schema, {_name, %{default_value: default_value, type: type}})
       when not is_nil(default_value) do
    type = Schema.lookup_type(schema, type)
    check_default_value_present(default_value, type)
  end

  defp check_args(_schema, _args), do: []

  defp check_default_value_present(default_value, %Type.Enum{} = type) do
    values = Enum.map(type.values, &elem(&1, 1).value)
    value_list = Enum.map(values, &"\n * #{&1}")

    if not (default_value in values) do
      detail = %{
        value_list: value_list,
        type: type.__reference__.identifier,
        default_value: default_value
      }

      [report(type.__reference__.location, detail)]
    else
      []
    end
  end

  defp check_default_value_present(_default_value, _type), do: []
end
