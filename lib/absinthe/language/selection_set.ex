defmodule Absinthe.Language.SelectionSet do
  @moduledoc false

  alias Absinthe.Language

  defstruct selections: [],
            loc: %{line: nil}

  @type t :: %__MODULE__{
          selections: [
            Language.FragmentSpread.t() | Language.InlineFragment.t() | Language.Field.t()
          ],
          loc: Language.loc_t()
        }
end
