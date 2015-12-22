defmodule Absinthe.Language.EnumValue do

  @type t :: %{value: any, loc: Absinthe.Language.loc_t}
  defstruct value: nil, loc: %{start: nil}

end
