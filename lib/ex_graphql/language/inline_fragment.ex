defmodule ExGraphQL.Language.InlineFragment do
  defstruct type_condition: nil, directives: [], selection_set: nil, loc: %{start: nil}
end
