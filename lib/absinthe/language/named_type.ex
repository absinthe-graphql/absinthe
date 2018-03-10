defmodule Absinthe.Language.NamedType do
  @moduledoc false

  alias Absinthe.{Blueprint, Language}

  defstruct name: nil,
            loc: %{start_line: nil}

  @type t :: %__MODULE__{
          name: String.t(),
          loc: Language.loc_t()
        }

  defimpl Blueprint.Draft do
    def convert(node, _doc) do
      %Blueprint.TypeReference.Name{
        name: node.name
      }
    end
  end
end
