defmodule Absinthe.Language.FragmentDefinition do

  @moduledoc false

  defstruct name: nil, type_condition: nil, directives: [], selection_set: nil, loc: %{start: nil}
end
