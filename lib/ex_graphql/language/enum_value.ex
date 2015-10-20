defmodule ExGraphQL.Language.EnumValue do

  @type t :: %{value: any, loc: ExGraphQL.Language.loc_t}
  defstruct value: nil, loc: %{start: nil}

end
