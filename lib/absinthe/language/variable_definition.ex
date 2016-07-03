defmodule Absinthe.Language.VariableDefinition do
  @moduledoc false

  alias Absinthe.{Blueprint, Language}

  defstruct [
    variable: nil,
    type: nil,
    default_value: nil,
    loc: %{start_line: nil}
  ]

  @type t :: %__MODULE__{
    variable: Language.Variable.t,
    type: Language.type_reference_t,
    default_value: any,
    loc: Language.loc_t
  }

  defimpl Blueprint.Draft do
    def convert(node, doc) do
      %Blueprint.VariableDefinition{
        name: node.variable.name,
        type: Absinthe.Blueprint.Draft.convert(node.type, doc),
        default_value: Absinthe.Blueprint.Draft.convert(node.default_value, doc),
      }
    end
  end

end
