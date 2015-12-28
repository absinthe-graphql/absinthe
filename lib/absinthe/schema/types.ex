defmodule Absinthe.Schema.Types do

  @moduledoc false

  alias Absinthe.Schema
  alias Absinthe.Traversal
  alias Absinthe.Type

  @type typemap_t :: %{atom => Type.t}
  @typep acc_t :: {typemap_t, typemap_t, [binary]}

  alias Absinthe.Type

  @builtin_type_modules [Type.Scalar]

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
        %{schema | types: result}
      other ->
        other
    end
  end

  # TODO: Support abstract types
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
          %{traversal | context: %{traversal.context | types: new_collected}}
        }
      # Already collected
      _ ->
        # No-op
        {:ok, acc, traversal}
    end
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
  @spec types_from_modules([atom]) :: typemap_t
  defp types_from_modules(modules) do
    modules
    |> Enum.map(&absinthe_types/1)
    |> Enum.reduce(%{}, fn
      mapping, acc ->
        acc |> Map.merge(mapping)
    end)
  end

end
