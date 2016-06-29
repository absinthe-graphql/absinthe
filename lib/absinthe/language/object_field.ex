defmodule Absinthe.Language.ObjectField do
  @moduledoc false

  alias Absinthe.Language

  defstruct [
    name: nil,
    value: nil,
    loc: %{start_line: nil}
  ]

  @type t :: %__MODULE__{
    name: binary,
    value: Language.value_t,
    loc: Language.loc_t
  }

end
