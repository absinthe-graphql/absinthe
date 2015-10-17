defmodule ExGraphQL.AST.OperationDefinition do
  defstruct operation: nil, name: nil, variable_definitions: [], directives: [], selection_set: nil, source_location: nil
end
