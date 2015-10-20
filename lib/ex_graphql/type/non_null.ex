defmodule ExGraphQL.Type.NonNull do

  @type t :: %{of_type: ExGraphQL.Type.nullable_t}
  defstruct of_type: nil

end
