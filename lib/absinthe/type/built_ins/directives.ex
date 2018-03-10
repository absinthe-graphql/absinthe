defmodule Absinthe.Type.BuiltIns.Directives do
  @moduledoc false

  use Absinthe.Schema.Notation
  alias Absinthe.Blueprint

  directive :include do
    description """
    Directs the executor to include this field or fragment only when the `if` argument is true."
    """

    arg :if, non_null(:boolean), description: "Included when true."

    on [:field, :fragment_spread, :inline_fragment]

    expand fn
      %{if: true}, node ->
        Blueprint.put_flag(node, :include, __MODULE__)

      _, node ->
        Blueprint.put_flag(node, :skip, __MODULE__)
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
        Blueprint.put_flag(node, :skip, __MODULE__)

      _, node ->
        Blueprint.put_flag(node, :include, __MODULE__)
    end
  end
end
