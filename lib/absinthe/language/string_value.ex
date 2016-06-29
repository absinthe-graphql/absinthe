defmodule Absinthe.Language.StringValue do
  @moduledoc false

  alias Absinthe.Language

  defstruct [
    value: nil,
    loc: %{}
  ]

  @type t :: %__MODULE__{
    value: binary,
    loc: Language.loc_t
  }

end
