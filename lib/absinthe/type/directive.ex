defmodule Absinthe.Type.Directive do

  @moduledoc """
  Used by the GraphQL runtime as a way of modifying execution
  behavior.

  Type system creators will usually not create these directly.
  """

  alias Absinthe.{Utils, Type}
  use Absinthe.Introspection.Kind

  @typedoc """
  A defined directive.

  * `:name` - The name of the directivee. Should be a lowercase `binary`. Set automatically when using `@absinthe :directive` from `Absinthe.Type.Definitions`.
  * `:description` - A nice description for introspection.
  * `:args` - A map of `Absinthe.Type.Argument` structs. See `Absinthe.Type.Definitions.args/1`.
  * `:on` - A list of places the directives can be used (can be `:operation`, `:fragment`, `:field`).
  * `:instruction` - A function that, given an argument, returns an instruction for the correct action to take

  The `:__reference__` key is for internal use.
  """
  @type t :: %{name: binary, description: binary, args: map, on: [atom], instruction: ((map) -> atom), __reference__: Type.Reference.t}
  defstruct name: nil, description: nil, args: nil, on: [], instruction: nil, __reference__: nil

  def build(%{attrs: attrs}) do
    args = attrs
    |> Keyword.get(:args, [])
    |> Enum.map(fn
      {name, attrs} ->
        {name, ensure_reference(attrs, attrs[:__reference__])}
    end)
    |> Type.Argument.build

    attrs = Keyword.put(attrs, :args, args)

    quote do: %unquote(__MODULE__){unquote_splicing(attrs)}
  end

  defp ensure_reference(arg_attrs, default_reference) do
    case Keyword.has_key?(arg_attrs, :__reference__) do
      true ->
        arg_attrs
      false ->
        Keyword.put(arg_attrs, :__reference__, default_reference)
    end
  end

  # Whether the directive is active in `place`
  @doc false
  @spec on?(t, atom) :: boolean
  def on?(%{on: places}, place) do
    Enum.member?(places, place)
  end

  # Check a directive and return an instruction
  @doc false
  @spec check(t, Language.t, map) :: atom
  def check(definition, %{__struct__: place}, args) do
    if on?(definition, place) && definition.instruction do
      definition.instruction.(args)
    else
      :ok
    end
  end

end
