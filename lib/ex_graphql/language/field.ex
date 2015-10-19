defmodule ExGraphQL.Language.Field do

  @type t :: %{alias: nil | binary, name: binary,
               arguments: [ExGraphQL.Language.Argument.t],
               directives: [ExGraphQL.Language.Directive.t],
               selection_set: ExGraphQL.Language.SelectionSet.t,
               loc: ExGraphQL.Language.loc_t}
  defstruct alias: nil, name: nil, arguments: [], directives: [], selection_set: nil, loc: %{start: nil}

  defimpl ExGraphQL.Language.Node do
    def children(node) do
      [node.arguments,
       node.directives,
       node.selection_set |> List.wrap]
      |> Enum.concat
    end
  end

end
