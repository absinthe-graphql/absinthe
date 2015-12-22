defmodule Absinthe.Language.FloatValue do

  @type t :: %{value: float, loc: Absinthe.Language.loc_t}
  defstruct value: nil, loc: %{}

end
