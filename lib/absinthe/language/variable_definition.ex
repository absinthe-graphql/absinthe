defmodule Absinthe.Language.VariableDefinition do
  @moduledoc false

  alias Absinthe.Language

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

end
