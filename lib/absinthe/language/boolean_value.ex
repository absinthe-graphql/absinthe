defmodule Absinthe.Language.BooleanValue do
  @moduledoc false

  alias Absinthe.Blueprint

  defstruct [
    :value,
    :loc
  ]

  @type t :: %__MODULE__{
          value: boolean,
          loc: Absinthe.Language.loc_t()
        }

  defimpl Blueprint.Draft do
    def convert(node, doc) do
      %Blueprint.Input.Boolean{
        value: Absinthe.Blueprint.Draft.convert(node.value, doc),
        source_location: source_location(node)
      }
    end

    defp source_location(%{loc: nil}), do: nil
    defp source_location(%{loc: loc}), do: Blueprint.Document.SourceLocation.at(loc.start_line)
  end
end
