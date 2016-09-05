defmodule Absinthe.Type.BuiltIns.Directives do
  @moduledoc false

  use Absinthe.Schema.Notation

  directive :include do
    description """
    Directs the executor to include this field or fragment only when the `if` argument is true."
    """

    arg :if, non_null(:boolean), description: "Included when true."

    on [:field, :fragment_spread, :inline_fragment]

    expand fn
      %{if: true}, node ->
        %{node | flags: [:include | node.flags]}
      _, node ->
        %{node | flags: [:skip | node.flags]}
    end

  end

  directive :skip do
    description """
    Directs the executor to skip this field or fragment when the `if` argument is true.
    """

    arg :if, non_null(:boolean), description: "Skipped when true."

    on [:field, :fragment_spread, :inline_fragment]

    expand fn
      %{if: true}, node ->
        %{node | flags: [:skip | node.flags]}
      _, node ->
        %{node | flags: [:include | node.flags]}
    end

  end

end
