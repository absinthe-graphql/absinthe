defmodule ExGraphQL.Execution.Variables do

  alias ExGraphQL.Language
  alias ExGraphQL.Type

  @type t :: %{schema: Type.Schema.t,
               ast_variables: [Language.VariableDefinition.t],
               provided_variables: %{binary => any}}
  defstruct schema: nil, ast_variables: [], provided_variables: %{}

  def get(variables, name) do

  end

end
