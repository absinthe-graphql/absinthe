defmodule ExGraphQL.Language.FieldDefinition do

  @type t :: %{name: binary, arguments: [ExGraphQL.Language.Argument.t], type: ExGraphQL.Language.type_reference_t, loc: ExGraphQL.Language.loc_t}
  defstruct name: nil, arguments: [], type: nil, loc: %{start: nil}

end
