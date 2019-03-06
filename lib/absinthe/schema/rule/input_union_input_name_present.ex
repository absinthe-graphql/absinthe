defmodule Absinthe.Schema.Rule.InputUnionInputNamePresent do
  use Absinthe.Schema.Rule

  alias Absinthe.{Schema, Type}
  require IEx

  @moduledoc false

  def explanation(%{
        data: %{input_union_type: input_union_type, input_object_type: input_object_type}
      }) do
    """
    The `__inputname` must be defined in a input_object :#{input_object_type} used in input_union :#{
      input_union_type
    }.

    Valid definition:
    input_object :#{input_union_type} do
      field :__inputname, non_null(:string)
    end
    """
  end

  def check(schema) do
    Schema.types(schema)
    |> Enum.flat_map(&check_type(schema, &1))
  end

  defp check_type(schema, %Type.InputUnion{types: types, __reference__: %{identifier: identifier}}) do
    Enum.flat_map(types, &check_fields(&1, identifier, schema))
  end

  defp check_type(_schema, _type), do: []

  defp check_fields(type, identifier, schema) do
    with %{fields: %{__inputname: %{type: %Absinthe.Type.NonNull{of_type: :string}}}} <-
           schema.__absinthe_type__(type) do
      []
    else
      %{__reference__: ref} ->
        data = %{input_union_type: identifier, input_object_type: type}
        [report(ref.location, data)]
    end
  end
end
