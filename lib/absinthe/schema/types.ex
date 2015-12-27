defmodule Absinthe.Schema.Types do

  alias Absinthe.Schema
  alias Absinthe.Traversal
  alias Absinthe.Type

  @type typemap_t :: %{atom => Type.t}
  @typep acc_t :: {[atom], typemap_t, [binary], typemap_t}

  alias Absinthe.Type

  @builtin_type_modules [Type.Scalar]

  @spec setup(Schema.t) :: Schema.t
  def setup(%{type_modules: extra_modules} = schema) do
    type_modules = @builtin_type_modules ++ extra_modules
    types_available = type_modules |> types_from_modules
    #IO.inspect(extras: extra_modules |> types_from_modules, extras: extra_modules, manual: extra_modules |> Enum.map(&absinthe_types/1))
    initial_collected = @builtin_type_modules |> types_from_modules
    case Traversal.reduce(schema, schema, {type_modules, types_available, [], initial_collected}, &collect_types/3) do
      {_, _, errors, _} when length(errors) > 0 ->
        %{schema | errors: schema.errors ++ errors}
      {_, _, _, result} ->
        %{schema | types: result}
      other ->
        other
    end
  end

  # TODO: Support abstract types
  @spec collect_types(Traversal.Node.t, Schema.t, acc_t) :: Traversal.instruction_t
  defp collect_types(%{__struct__: str, type: possibly_wrapped_type} = node, traversal, {type_modules, avail, errors, collect} = acc) do
    type = possibly_wrapped_type |> Type.unwrap
    case {collect[type], avail[type]} do
      # Invalid
      {nil, nil} ->
        avail_names = avail |> Map.keys |> Enum.join(", ")
        {:prune, {avail, ["Missing type #{type}; not found in #{avail_names}"|errors], collect}, traversal}
      # Not yet collected
      {nil, found} ->
        new_collected = collect |> Map.put(type, found)
        {
          :ok,
          {type_modules, avail, errors, new_collected},
          %{traversal | schema: %{traversal.schema | types: new_collected}}
        }
      # Already collected
      {found, _} ->
        # TODO: Pruning prevents arguments from being added to the type map
        {:prune, acc, traversal}
    end
  end
  defp collect_types(node, traversal, acc) do
    {:ok, acc, traversal}
  end

  defp absinthe_types(mod) do
    try do
      mod.absinthe_types
    rescue
      UndefinedFunctionError -> %{}
    end
  end

  defp extra_type_modules do
    Application.get_env(:absinthe, :type_modules, [])
    |> List.wrap
  end

  @spec types_from_modules([atom]) :: typemap_t
  def types_from_modules(modules) do
    modules
    |> Enum.map(&absinthe_types/1)
    |> Enum.reduce(%{}, fn
      mapping, acc ->
        acc |> Map.merge(mapping)
    end)
  end

end
