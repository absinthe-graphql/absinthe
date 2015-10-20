defmodule ExGraphQL.Language.EnumTypeDefinition do

  @type t :: %{name: binary, values: [any], loc: ExGraphQL.Language.loc_t}
  defstruct name: nil, values: [], loc: %{start: nil}

end
