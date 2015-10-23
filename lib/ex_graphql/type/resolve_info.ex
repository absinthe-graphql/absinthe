defmodule ExGraphQL.Type.ResolveInfo do
  @type t :: %{} # TODO
  defstruct field_name: nil, field_ASTs: [], return_type: nil, parent_type: nil, schema: nil, fragments: %{}, root_value: nil, operation: nil, variable_values: %{}

  use ExGraphQL.Type.Creation
  def setup(struct), do: {:ok, struct}
end
