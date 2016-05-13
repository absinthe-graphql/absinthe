defmodule Absinthe.Language.Field do

  @moduledoc false

  @type t :: %{alias: nil | binary, name: binary,
               arguments: [Absinthe.Language.Argument.t],
               directives: [Absinthe.Language.Directive.t],
               selection_set: Absinthe.Language.SelectionSet.t,
               loc: Absinthe.Language.loc_t}
  defstruct alias: nil, name: nil, arguments: [], directives: [], selection_set: nil, loc: %{start_line: nil}

  defimpl Absinthe.Traversal.Node do
    def children(node, _schema) do
      [node.arguments,
       node.directives,
       node.selection_set |> List.wrap]
      |> Enum.concat
    end
  end

end
