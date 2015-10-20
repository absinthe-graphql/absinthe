defmodule ExGraphQL.Type.Object do

  defstruct name: nil, description: nil, fields: nil, interfaces: [], isTypeOf: nil
  @type t :: %{name: binary, description: binary, fields: map | (() -> map), interfaces: [ExGraphQL.Type.Interface.t], isTypeOf: ((any) -> boolean)}

end
