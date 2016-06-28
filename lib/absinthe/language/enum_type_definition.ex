defmodule Absinthe.Language.EnumTypeDefinition do

  @moduledoc false

  @type t :: %{name: binary, values: [any], loc: Absinthe.Language.loc_t}
  defstruct name: nil, values: [], loc: %{start_line: nil}

end
