defmodule Absinthe.Language.FloatValue do
  @moduledoc false

  alias Absinthe.{Blueprint, Language}

  defstruct [
    :value,
    :loc
  ]

  @type t :: %__MODULE__{
          value: float,
          loc: Language.loc_t()
        }

  defimpl Blueprint.Draft do
    def convert(node, _doc) do
      %Blueprint.Input.Float{
        value: node.value,
        source_location: source_location(node)
      }
    end

    defp source_location(%{loc: nil}), do: nil
    defp source_location(%{loc: loc}), do: Blueprint.Document.SourceLocation.at(loc.start_line)
  end
end
