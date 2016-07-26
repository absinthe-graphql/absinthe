defmodule Absinthe.Type.BuiltIns.Directives do
  use Absinthe.Schema.Notation

  @moduledoc false

  directive :include do
    description """
    Directs the executor to include this field or fragment only when the `if` argument is true."
    """

    arg :if, non_null(:boolean), description: "Included when true."

    on [:field, :fragment_spread, :inline_fragment]

    instruction fn
      %{if: true} ->
        :include
      _ ->
        :skip
    end

  end

  directive :skip do
    description """
    Directs the executor to skip this field or fragment when the `if` argument is true.
    """

    arg :if, non_null(:boolean), description: "Skipped when true."

    on [:field, :fragment_spread, :inline_fragment]

    instruction fn
      %{if: true} ->
        :skip
      _ ->
        :include
    end

  end

end
