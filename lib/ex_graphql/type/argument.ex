defmodule ExGraphQL.Type.Argument do

  @type t :: %{name: binary,
               type: ExGraphQL.Type.input_t,
               default_value: any,
               description: binary | nil}

  defstruct name: nil, description: nil, type: nil, default_value: nil

end
