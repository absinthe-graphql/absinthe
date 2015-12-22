defmodule Absinthe.Language.Field do

  @type t :: %{alias: nil | binary, name: binary,
               arguments: [Absinthe.Language.Argument.t],
               directives: [Absinthe.Language.Directive.t],
               selection_set: Absinthe.Language.SelectionSet.t,
               loc: Absinthe.Language.loc_t}
  defstruct alias: nil, name: nil, arguments: [], directives: [], selection_set: nil, loc: %{start: nil}

  defimpl Absinthe.Language.Node do
    def children(node) do
      [node.arguments,
       node.directives,
       node.selection_set |> List.wrap]
      |> Enum.concat
    end
  end

end
