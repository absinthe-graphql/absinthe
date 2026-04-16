defmodule Absinthe.Language.Comment do
  @moduledoc false

  alias Absinthe.Language

  defstruct value: nil, loc: %{line: nil}

  @type t :: %__MODULE__{
          value: nil | String.t(),
          loc: Language.loc_t()
        }
end
