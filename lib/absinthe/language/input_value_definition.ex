defmodule Absinthe.Language.InputValueDefinition do
  @moduledoc false

  alias Absinthe.Language

  defstruct [
    name: nil,
    type: nil,
    default_value: nil,
    loc: %{start_line: nil}
  ]

  # TODO: Make 'type' and 'default_value' types more specific
  @type t :: %__MODULE__{
    name: binary,
    type: any,
    default_value: any,
    loc: Language.loc_t
  }

end
