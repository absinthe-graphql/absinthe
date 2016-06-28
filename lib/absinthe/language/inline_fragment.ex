defmodule Absinthe.Language.InlineFragment do

  @moduledoc false

  @type t :: t
  defstruct type_condition: nil, directives: [], selection_set: nil, loc: %{start_line: nil}

  defimpl Absinthe.Traversal.Node do
    def children(node, _schema) do
      [List.wrap(node.type_condition),
       node.directives,
       List.wrap(node.selection_set)]
      |> Enum.concat
    end
  end

end
