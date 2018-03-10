defmodule Absinthe.Language.ListType do
  @moduledoc false

  alias Absinthe.{Blueprint, Language}

  defstruct type: nil,
            loc: %{start_line: nil}

  @type t :: %__MODULE__{
          type: Language.type_reference_t(),
          loc: Language.loc_t()
        }

  defimpl Blueprint.Draft do
    def convert(node, doc) do
      %Blueprint.TypeReference.List{
        of_type: Absinthe.Blueprint.Draft.convert(node.type, doc)
      }
    end
  end
end
