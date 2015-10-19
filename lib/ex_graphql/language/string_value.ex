defmodule ExGraphQL.Language.StringValue do

  @type t :: %{value: binary, loc: ExGraphQL.Language.loc_t}
  defstruct value: nil, loc: %{}

end
