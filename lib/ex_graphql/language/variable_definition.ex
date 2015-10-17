defmodule ExGraphQL.Language.VariableDefinition do
  defstruct variable: nil, type: nil, default_value: nil, loc: %{start: nil}
end
