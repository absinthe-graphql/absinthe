defmodule Absinthe.Language.ListType do
  @moduledoc false

  alias Absinthe.Language

  defstruct [
    type: nil,
    loc: %{start_line: nil}
  ]

  @type t :: %__MODULE__{
    type: Language.type_reference_t,
    loc: Language.loc_t
  }

end
