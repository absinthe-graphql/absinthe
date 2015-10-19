defmodule ExGraphQL.Language.Directive do

  @type t :: %{name: binary, arguments: [ExGraphQL.Language.Argument],
               loc: ExGraphQL.Language.loc_t}
  defstruct name: nil, arguments: [], loc: %{start: nil}
end
