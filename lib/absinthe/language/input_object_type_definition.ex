defmodule Absinthe.Language.InputObjectTypeDefinition do

  @moduledoc false

  defstruct [
    name: nil,
    fields: [],
    loc: %{start_line: nil}
  ]

  @type t :: %__MODULE__{
    name: binary,
    fields: [Language.FieldDefinition.t],
    loc: Language.loc_t
  }

end
