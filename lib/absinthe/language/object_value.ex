defmodule Absinthe.Language.ObjectValue do
  @moduledoc false

  alias Absinthe.{Blueprint, Language}

  defstruct fields: [],
            loc: nil

  @type t :: %__MODULE__{
          fields: [Language.ObjectField.t()],
          loc: Language.loc_t()
        }

  defimpl Blueprint.Draft do
    def convert(node, doc) do
      %Blueprint.Input.Object{
        fields: Absinthe.Blueprint.Draft.convert(node.fields, doc),
        source_location: source_location(node)
      }
    end

    defp source_location(%{loc: nil}), do: nil
    defp source_location(%{loc: loc}), do: Blueprint.Document.SourceLocation.at(loc.start_line)
  end
end
