defmodule ExGraphQL.Language.OperationDefinition do
  defstruct operation: nil, name: nil, variable_definitions: [], directives: [], selection_set: nil, loc: %{start: nil}
end
