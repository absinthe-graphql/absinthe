defmodule ExGraphQL.Language.FloatValue do

  @type t :: %{value: float, loc: ExGraphQL.Language.loc_t}
  defstruct value: nil, loc: %{}

end
