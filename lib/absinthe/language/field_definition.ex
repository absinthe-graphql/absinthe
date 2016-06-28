defmodule Absinthe.Language.FieldDefinition do

  @moduledoc false

  @type t :: %{name: binary, arguments: [Absinthe.Language.Argument.t], type: Absinthe.Language.type_reference_t, loc: Absinthe.Language.loc_t}
  defstruct name: nil, arguments: [], type: nil, loc: %{start_line: nil}

end
