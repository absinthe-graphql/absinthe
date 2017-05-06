defmodule Absinthe.Language.ObjectField do
  @moduledoc false

  alias Absinthe.{Blueprint, Language}

  defstruct [
    name: nil,
    value: nil,
    loc: %{start_line: nil}
  ]

  @type t :: %__MODULE__{
    name: String.t,
    value: Language.value_t,
    loc: Language.loc_t
  }

  defimpl Blueprint.Draft do
    def convert(node, doc) do
      converted_value = Blueprint.Draft.convert(node.value, doc)

      %Blueprint.Input.Field{
        name: node.name,
        input_value: %Blueprint.Input.Value{literal: converted_value, normalized: converted_value},
        source_location: source_location(node),
      }
    end
    defp source_location(%{loc: nil}), do: nil
    defp source_location(%{loc: loc}), do: Blueprint.Document.SourceLocation.at(loc.start_line)
  end

end
