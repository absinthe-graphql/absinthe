defmodule Absinthe.Schema.TypeMap do

  @moduledoc false

  alias Absinthe.Schema
  alias Absinthe.Traversal
  alias Absinthe.Type

  @typep ident_map_t :: %{atom => Type.t}
  @typep name_map_t :: %{binary => Type.t}
  @typep acc_t :: {ident_map_t, ident_map_t, [binary]}

  @type t :: %{by_identifier: ident_map_t, by_name: name_map_t}
  defstruct by_identifier: %{}, by_name: %{}

  alias __MODULE__
  alias Absinthe.Type

  @builtin_type_modules [Type.Scalar]

  @behaviour Access
  def get_and_update(type_map, key, fun) do
    Map.get_and_update(type_map.by_identifier, key, fun)
  end
  def fetch(container, key) do
    Map.fetch(container.by_identifier, key)
  end

  # Discover the types available to and defined for a schema
  @doc false
  @spec setup(Schema.t) :: Schema.t
  def setup(%{type_modules: extra_modules} = schema) do
    type_modules = @builtin_type_modules ++ extra_modules
    types_available = type_modules |> types_from_modules
    initial_collected = @builtin_type_modules |> types_from_modules
    case Traversal.reduce(schema, schema, {types_available, initial_collected, []}, &collect_types/3) do
      {_, _, errors} when length(errors) > 0 ->
        %{schema | errors: schema.errors ++ errors}
      {_, result, _} ->
        all = result |> add_from_interfaces(types_available)
        by_name = for {_, type} <- all, into: %{}, do: {type.name, type}
        %{schema | types: struct(TypeMap, by_identifier: all, by_name: by_name)}
      other ->
        other
    end
  end

  @spec collect_types(Traversal.Node.t, Traversal.t, acc_t) :: Traversal.instruction_t
  defp collect_types(%{type: possibly_wrapped_type}, traversal, {avail, collect, errors} = acc) do
    type = possibly_wrapped_type |> Type.unwrap
    case {collect[type], avail[type]} do
      # Invalid
      {nil, nil} ->
        avail_names = avail |> Map.keys |> Enum.join(", ")
        {:prune, {avail, collect, ["Missing type #{type}; not found in #{avail_names}" | errors]}, traversal}
      # Not yet collected
      {nil, found} ->
        new_collected = collect |> Map.put(type, found)
        {
          :ok,
          {avail, new_collected, errors},
          %{traversal | context: %{traversal.context | types: struct(TypeMap, by_identifier: new_collected)}}
        }
      # Already collected
      _ ->
        # No-op
        {:ok, acc, traversal}
    end
  end
  # Bare type; likely the name of an interface.
  # Wrap it just like a type entry and process, reusing the
  # logic above
  defp collect_types(node, traversal, acc)  when is_atom(node) do
    collect_types(%{type: node}, traversal, acc)
  end
  defp collect_types(_node, traversal, acc) do
    {:ok, acc, traversal}
  end

  # Gracefully attempt to get the absinthe types
  # on a given type module
  defp absinthe_types(mod) do
    try do
      mod.absinthe_types
    rescue
      UndefinedFunctionError -> %{}
    end
  end

  # Extract a mapping of all the types in a set of modules
  @spec types_from_modules([atom]) :: ident_map_t
  defp types_from_modules(modules) do
    modules
    |> Enum.map(&absinthe_types/1)
    |> Enum.reduce(%{}, fn
      mapping, acc ->
        acc |> Map.merge(mapping)
    end)
  end

  # Find any types that implement an interface associated with
  # the schema
  @spec add_from_interfaces(ident_map_t, ident_map_t) :: ident_map_t
  defp add_from_interfaces(result, avail) do
    avail
    |> Enum.reduce(result, fn
      {name, %{interfaces: ifaces} = type}, acc ->
        if result[name] do
          acc
        else
          ifaces
          |> Enum.reduce(acc, fn
            iface, iface_acc ->
            if iface_acc[iface] && !iface_acc[type] do
              iface_acc |> Map.merge(%{name => type})
            else
              iface_acc
            end
          end)
        end
      _, acc ->
        acc
    end)
  end

end
