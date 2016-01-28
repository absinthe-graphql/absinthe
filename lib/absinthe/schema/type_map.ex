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
  alias Absinthe.Introspection

  @builtin_type_modules [
    Type.Scalar,
    Type.Directive,
    Introspection.Types
  ]

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
  def setup(%{type_modules: extra_modules} = schema_without_types) do
    type_modules = @builtin_type_modules ++ extra_modules
    with {:ok, types_available} <- types_from_modules(type_modules),
         {:ok, initial_collected} <- types_from_modules(@builtin_type_modules) do
      schema = %{schema_without_types |
                 types: %TypeMap{by_identifier: initial_collected},
                 directives: type_modules |> directives_from_modules}
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
    |> case do
      {:error, err} ->
         %{schema_without_types |
           types: struct(TypeMap, by_identifier: %{}, by_name: %{}),
           errors: schema_without_types.errors ++ [err]}
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
  defp collect_types(node, traversal, acc) when is_atom(node) do
    collect_types(%{type: node}, traversal, acc)
  end
  defp collect_types(%Type.Object{reference: %{identifier: ident}}, traversal, acc) do
    # Could be a root item, pretend it's a reference:
    collect_types(%{type: ident}, traversal, acc)
  end
  defp collect_types(_node, traversal, acc) do
    {:ok, acc, traversal}
  end

  # Extract a mapping of all the types in a set of modules
  @spec types_from_modules([atom]) :: {:ok, ident_map_t} | {:error, binary}
  defp types_from_modules(modules) do
    mod_types = for mod <- modules, into: %{}, do: {mod, mod.__absinthe_info__(:types)}
    with :ok <- check_collision(mod_types) do
      result = mod_types
      |> Map.values
      |> Enum.reduce(%{}, &Map.merge(&1, &2))
      {:ok, result}
    end
  end

  # Get a list of the possible n-length combinations of members of a list
  @spec combination(integer, [any]) :: [list]
  defp combination(0, _), do: [[]]
  defp combination(_, []), do: []
  defp combination(n, [x|xs]) do
    (for y <- combination(n - 1, xs), do: [x|y]) ++ combination(n, xs)
  end

  @spec check_collision(%{atom => %{atom => Absinthe.Type.t}}) :: :ok | {:error, %{atom => [atom]}}
  defp check_collision(mod_types) do
    combos = combination(2, mod_types |> Map.keys)
    with :ok <- do_check_collision(combos, "Type name collisions were found for the following types, in the associated type modules", &(mod_types[&1] |> Map.values |> Enum.map(fn t -> t.name end))),
         :ok <- do_check_collision(combos, "Type ident collisions were found for the following types, in the associated type modules", &(mod_types[&1] |> Map.keys)) do
      :ok
    end
  end

  # Check collision of items relating to pairs of type modules
  @spec do_check_collision([list], binary, ((atom) -> [any])) :: :ok | {:error, binary}
  defp do_check_collision(pairs, error_message, extractor) do
    pairs
    |> Enum.reduce(%{}, fn
      [mod1, mod2], acc ->
        items1 = extractor.(mod1) |> MapSet.new
        items2 = extractor.(mod2) |> MapSet.new
        case MapSet.intersection(items1, items2) |> MapSet.to_list do
          [] ->
            acc
          collision ->
            collision
            |> Enum.reduce(acc, fn
              item, item_acc ->
                Map.put(item_acc, item, [{mod1, mod2} | Map.get(item_acc, item, [])])
            end)
        end
    end)
    |> case do
      %{} = a when map_size(a) == 0 ->
        :ok
      other ->
        {:error, error_message <> ": #{inspect other}"}
    end
  end

  # Extract a mapping of all the defined directives in a set of modules
  @spec directives_from_modules([atom]) :: ident_map_t
  defp directives_from_modules(modules) do
    modules
    |> Enum.map(&(&1.__absinthe_info__(:directives)))
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
