defmodule Absinthe.Language.FragmentDefinition do
  defstruct name: nil, type_condition: nil, directives: [], selection_set: nil, loc: %{start: nil}
end
