defmodule Absinthe.Language.VariableDefinition do
  @moduledoc false

  alias Absinthe.{Blueprint, Language}

  defstruct variable: nil,
            type: nil,
            default_value: nil,
            loc: %{start_line: nil}

  @type t :: %__MODULE__{
          variable: Language.Variable.t(),
          type: Language.type_reference_t(),
          default_value: any,
          loc: Language.loc_t()
        }

  defimpl Blueprint.Draft do
    def convert(node, doc) do
      %Blueprint.Document.VariableDefinition{
        name: node.variable.name,
        type: Blueprint.Draft.convert(node.type, doc),
        default_value: Blueprint.Draft.convert(node.default_value, doc),
        source_location: Blueprint.Document.SourceLocation.at(node.loc.start_line)
      }
    end
  end
end
