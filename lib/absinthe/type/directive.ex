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

  * `:name` - The name of the directivee. Should be a lowercase `binary`. Set automatically when using `@absinthe :directive` from `Absinthe.Type.Definitions`.
  * `:description` - A nice description for introspection.
  * `:args` - A map of `Absinthe.Type.Argument` structs. See `Absinthe.Type.Definitions.args/1`.
  * `:on` - A list of places the directives can be used (can be `:operation`, `:fragment`, `:field`).
  * `:instruction` - A function that, given an argument, returns an instruction for the correct action to take

  The `:reference` key is for internal use.
  """
  @type t :: %{name: binary, description: binary, args: map, on: [atom], instruction: ((map) -> atom), reference: Type.Reference.t}
  defstruct name: nil, description: nil, args: nil, on: [], instruction: nil, reference: nil

  use Absinthe.Type.Definitions
  alias Absinthe.Type
  alias Absinthe.Language

  @absinthe :directive
  def include do
    %Type.Directive{
      description: "Directs the executor to include this field or fragment only when the `if` argument is true.",
      args: args(
        if: [type: non_null(:boolean), description: "Included when true."]
      ),
      on: [Language.FragmentSpread, Language.Field, Language.InlineFragment],
      instruction: fn
        %{if: true} ->
          :include
        _ ->
          :skip
      end
    }
  end

  @absinthe :directive
  def skip do
    %Type.Directive{
      description: "Directs the executor to skip this field or fragment when the `if` argument is true.",
      args: args(
        if: [type: non_null(:boolean), description: "Skipped when true."]
      ),
      on: [Language.FragmentSpread, Language.Field, Language.InlineFragment],
      instruction: fn
        %{if: true} ->
          :skip
        _ ->
          :include
      end
    }
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
