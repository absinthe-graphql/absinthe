defmodule Absinthe.Language.DirectiveDefinition do

  @moduledoc false

  @type t :: %{name: binary, arguments: [Absinthe.Language.Argument.t], locations: [any], loc: Absinthe.Language.loc_t}
  defstruct name: nil, arguments: [], location: [], loc: %{start: nil}

end
