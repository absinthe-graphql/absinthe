defmodule Absinthe.Language.EnumValue do

  @moduledoc false

  @type t :: %{value: any, loc: Absinthe.Language.loc_t}
  defstruct value: nil, loc: %{start_line: nil}

end
