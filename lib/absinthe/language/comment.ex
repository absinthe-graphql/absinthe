defmodule Absinthe.Language.Comment do
  @moduledoc false

  alias Absinthe.{Blueprint, Language}

  defstruct value: nil, loc: %{line: nil}

  @type t :: %__MODULE__{
          value: nil | String.t(),
          loc: Language.loc_t()
        }

  defimpl Blueprint.Draft do
    # Comments are not part of the executable document; skip them silently.
    def convert(_comment, _doc), do: nil
  end

  defimpl Inspect do
    defdelegate inspect(term, options), to: Absinthe.Language.Render
  end
end
