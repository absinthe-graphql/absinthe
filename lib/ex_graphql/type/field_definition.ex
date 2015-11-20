defmodule ExGraphQL.Type.FieldDefinition do

  @type t :: %{name: binary,
               description: binary | nil,
               type: ExGraphQL.Type.output_t,
               args: %{(binary | atom) => ExGraphQL.Type.Argument.t} | nil,
               resolve: ((any, %{binary => any} | nil, ExGraphQL.Type.ResolveInfo.t | nil) -> ExGraphQL.Type.output_t) | nil}

  defstruct name: nil, description: nil, type: nil, args: %{}, resolve: nil

end
