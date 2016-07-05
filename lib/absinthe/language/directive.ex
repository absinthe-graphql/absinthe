defmodule Absinthe.Language.Directive do

  @moduledoc false

  alias Absinthe.{Blueprint, Language}

  defstruct [
    name: nil,
    arguments: [],
    loc: %{start_line: nil}
  ]

  @type t :: %__MODULE__{
    name: String.t,
    arguments: [Language.Argument],
    loc: Language.loc_t
  }

  defimpl Blueprint.Draft do
    def convert(node, doc) do
      %Blueprint.Directive{
        name: node.name,
        arguments: Absinthe.Blueprint.Draft.convert(node.arguments, doc),
        source_location: Blueprint.Document.SourceLocation.at(node.loc.start_line),
      }
    end
  end

end
