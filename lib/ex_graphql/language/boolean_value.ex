defmodule ExGraphQL.Language.BooleanValue do

  @type t :: %{value: boolean, loc: ExGraphQL.Language.loc_t}
  defstruct value: nil, loc: %{}

end
