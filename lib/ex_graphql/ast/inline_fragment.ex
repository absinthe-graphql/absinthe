defmodule ExGraphQL.AST.InlineFragment do
  defstruct type_condition: nil, directives: [], selection_set: nil, loc: %{start: nil}
end
