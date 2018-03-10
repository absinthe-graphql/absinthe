defmodule Absinthe.Language.NullValue do
  @moduledoc false

  alias Absinthe.{Blueprint, Language}

  defstruct [
    :loc
  ]

  @type t :: %__MODULE__{
          loc: Language.loc_t()
        }

  defimpl Blueprint.Draft do
    def convert(node, _doc) do
      %Blueprint.Input.Null{
        source_location: source_location(node)
      }
    end

    defp source_location(%{loc: nil}), do: nil
    defp source_location(%{loc: loc}), do: Blueprint.Document.SourceLocation.at(loc.start_line)
  end
end
