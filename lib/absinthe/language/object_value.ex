defmodule Absinthe.Language.ObjectValue do
  @moduledoc false

  alias Absinthe.Language

  defstruct [
    fields: [],
    loc: %{start_line: nil}
  ]

  @type t :: %__MODULE__{
    fields: [Language.ObjectField.t],
    loc: Language.loc_t
  }

end
