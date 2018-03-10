defmodule Absinthe.Language.EnumValue do
  @moduledoc false

  alias Absinthe.{Blueprint, Language}

  defstruct value: nil,
            loc: %{start_line: nil}

  @type t :: %__MODULE__{
          value: any,
          loc: Language.loc_t()
        }

  defimpl Blueprint.Draft do
    def convert(node, _doc) do
      %Blueprint.Input.Enum{
        value: node.value,
        source_location: source_location(node)
      }
    end

    defp source_location(%{loc: nil}), do: nil
    defp source_location(%{loc: loc}), do: Blueprint.Document.SourceLocation.at(loc.start_line)
  end
end
