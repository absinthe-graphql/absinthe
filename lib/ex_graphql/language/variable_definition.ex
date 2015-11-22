defmodule ExGraphQL.Language.VariableDefinition do

  alias ExGraphQL.Language

  @type t :: %{variable: Language.Variable.t,
               type: Language.type_reference_t
               default_value: any,
               loc: Language.loc_t}
  defstruct variable: nil, type: nil, default_value: nil, loc: %{start: nil}
end
