defmodule Absinthe.Language.BooleanValue do

  @moduledoc false

  @type t :: %{value: boolean, loc: Absinthe.Language.loc_t}
  defstruct value: nil, loc: %{}

end
