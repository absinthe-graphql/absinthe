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
        case types[iface] do
          %Type.Interface{} = iface_type_struct ->
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
                err = "The :#{identifier} object type does not implement the :#{iface} interface type, as declared"
                {mapping, [err | errors]}
            end
            |> check_resolvers(identifier, type_struct, iface, iface_type_struct)
          %{__struct__: struct_type} ->
            short_name = struct_type |> Module.split |> List.last
            err = "The :#{identifier} object type may only implement Interface types, it cannot implement :#{iface} (#{short_name})"
            {mapping, [err | errors]}
        end
    end)
  end

  defp check_resolvers({mapping, errors} = acc, identifier, %{is_type_of: nil}, iface, %{resolve_type: nil}) do
    err = "Interface type :#{iface} does not provide a `resolve_type` function and implementing type :#{identifier} does not provide an `is_type_of` function. There is no way to resolve this implementing type during execution."
    {mapping, [err | errors]}
  end
  defp check_resolvers(acc, _identifier, _type_struct, _iface, _iface_type_struct) do
    acc
  end

  # Generate an implementation error
  @spec error(atom, atom, atom) :: binary
  defp error(:implementation, identifier, interface) do

  end
  defp error(:bad_type, identifier, interface) do
    "The :#{identifier} object type does not implement the :#{interface} interface type, as declared"
  end

end
