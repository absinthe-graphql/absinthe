defmodule Absinthe.Type.Directive do
  @moduledoc """
  Used by the GraphQL runtime as a way of modifying execution
  behavior.

  Type system creators will usually not create these directly.
  """

  alias Absinthe.Type
  alias Absinthe.Language
  use Absinthe.Introspection.Kind

  @typedoc """
  A defined directive.

  * `:name` - The name of the directivee. Should be a lowercase `binary`. Set automatically.
  * `:description` - A nice description for introspection.
  * `:args` - A map of `Absinthe.Type.Argument` structs. See `Absinthe.Schema.Notation.arg/1`.
  * `:locations` - A list of places the directives can be used.
  * `:instruction` - A function that, given an argument, returns an instruction for the correct action to take

  The `:__reference__` key is for internal use.
  """
  @type t :: %{
          name: binary,
          description: binary,
          identifier: atom,
          args: map,
          locations: [location],
          expand: nil | (Absinthe.Blueprint.node_t(), map -> {Absinthe.Blueprint.t(), map}),
          instruction: (map -> atom),
          __reference__: Type.Reference.t()
        }

  @type location ::
          :query | :mutation | :field | :fragment_definition | :fragment_spread | :inline_fragment

  defstruct name: nil,
            description: nil,
            identifier: nil,
            args: nil,
            locations: [],
            expand: nil,
            instruction: nil,
            __reference__: nil

  def build(%{attrs: attrs}) do
    args =
      attrs
      |> Keyword.get(:args, [])
      |> Enum.map(fn {name, attrs} ->
        {name, ensure_reference(attrs, attrs[:__reference__])}
      end)
      |> Type.Argument.build()

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
  @spec on?(t, Language.t()) :: boolean
  def on?(%{locations: locations}, place) do
    Enum.any?(locations, &do_on?(&1, place))
  end

  # Operations
  defp do_on?(location, %Language.OperationDefinition{operation: location}), do: true
  defp do_on?(:field, %Language.Field{}), do: true
  defp do_on?(:fragment_definition, %Language.Fragment{}), do: true
  defp do_on?(:fragment_spread, %Language.FragmentSpread{}), do: true
  defp do_on?(:inline_fragment, %Language.InlineFragment{}), do: true
  # TODO: Schema definitions to support Schema input
  defp do_on?(_, _), do: false

  # Check a directive and return an instruction
  @doc false
  @spec check(t, Language.t(), map) :: atom
  def check(definition, place, args) do
    if on?(definition, place) && definition.instruction do
      definition.instruction.(args)
    else
      :ok
    end
  end
end
