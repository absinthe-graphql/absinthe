defmodule Absinthe.Language.Variable do
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
      %Blueprint.Input.Variable{
        name: node.name,
        source_location: source_location(node)
      }
    end

    defp source_location(%{loc: nil}), do: nil
    defp source_location(%{loc: loc}), do: Blueprint.Document.SourceLocation.at(loc.start_line)
  end
end
