defmodule Absinthe.Type.BuiltIns.Directives do
  use Absinthe.Schema.Notation

  alias Absinthe.Type
  alias Absinthe.Language

  @doc """
  Directs the executor to include this field or fragment only when the `if` argument is true."
  """
  directive :include do

    @doc "Included when true."
    arg :if, non_null(:boolean)

    on [Language.FragmentSpread, Language.Field, Language.InlineFragment]

    instruction fn
      %{if: true} ->
        :include
      _ ->
        :skip
    end

  end

  @doc """
  Directs the executor to skip this field or fragment when the `if` argument is true.
  """
  directive :skip do

    @doc "Skipped when true."
    arg :if, non_null(:boolean)

    on [Language.FragmentSpread, Language.Field, Language.InlineFragment]

    instruction fn
      %{if: true} ->
        :skip
      _ ->
        :include
    end

  end

  # Whether the directive is active in `place`
  @doc false
  @spec on?(Type.Directive.t, atom) :: boolean
  def on?(%{on: places}, place) do
    Enum.member?(places, place)
  end

  # Check a directive and return an instruction
  @doc false
  @spec check(Type.Directive.t, Language.t, map) :: atom
  def check(definition, %{__struct__: place}, args) do
    if on?(definition, place) && definition.instruction do
      definition.instruction.(args)
    else
      :ok
    end
  end

end
