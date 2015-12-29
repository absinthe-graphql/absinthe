defmodule Absinthe.Language.FloatValue do

  @moduledoc false

  @type t :: %{value: float, loc: Absinthe.Language.loc_t}
  defstruct value: nil, loc: %{}

end
