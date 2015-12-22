defmodule Absinthe.Language.BooleanValue do

  @type t :: %{value: boolean, loc: Absinthe.Language.loc_t}
  defstruct value: nil, loc: %{}

end
