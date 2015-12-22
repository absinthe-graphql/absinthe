defmodule Absinthe.Language.StringValue do

  @type t :: %{value: binary, loc: Absinthe.Language.loc_t}
  defstruct value: nil, loc: %{}

end
