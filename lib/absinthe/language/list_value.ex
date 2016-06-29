defmodule Absinthe.Language.ListValue do
  @moduledoc false

  alias Absinthe.Language

  defstruct [
    values: [],
    loc: %{start_line: nil}
  ]

  @type t :: %__MODULE__{
    values: [Language.value_t],
    loc: Language.loc_t
  }
end
