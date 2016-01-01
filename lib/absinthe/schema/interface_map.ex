defmodule Absinthe.Schema.InterfaceMap do
  # Builds a mapping of interface names to the types that implement them

  @moduledoc false

  alias Absinthe.Type
  alias Absithe.Schema.TypeMap
  alias Absinthe.Schema

  @type t :: %{atom => [atom]}
  @typep acc_t :: {t, [binary]}

  # Discover the mappings of interfaces to types that implement them
  @doc false
  @spec setup(Schema.t) :: Schema.t
  def setup(%{types: types} = schema) do
    {mapping, errors} = types
    |> Enum.reduce({%{}, []}, fn
      {_, %{interfaces: _}} = implementor, acc ->
        add_entry(implementor, types, acc)
      _, acc ->
        acc
    end)
    %{schema | interfaces: mapping, errors: schema.errors ++ errors}
  end

  # Add an entry for an implementor (ind it's interfaces, if necessary)
  @spec add_entry({atom, Type.t}, TypeMap.t, acc_t) :: acc_t
  defp add_entry({identifier, %{interfaces: interfaces} = type_struct}, types, acc) do
    interfaces
    |> Enum.reduce(acc, fn
      iface, {mapping, errors} ->
        iface_type_struct = types[iface]
        iface_fields = iface_type_struct.fields
        case type_struct.fields do
          ^iface_fields ->
            {
              Map.merge(mapping, %{iface => [identifier]}, fn
                _, v1, v2 -> v1 ++ v2
              end),
              errors
            }
          _ ->
            {mapping, [error(identifier, iface) | errors]}
        end
    end)
  end

  # Generate an implementation error
  @spec error(atom, atom) :: binary
  defp error(identifier, interface) do
    "The :#{identifier} object type does not implement the :#{interface} interface type, as declared"
  end

end
