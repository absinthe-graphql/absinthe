defmodule ExGraphQL.Type.Union do

  @type t :: %{name: binary,
               description: binary,
               resolve_type: ((any, ExGraphQL.Type.ResolveInfo.t) -> ExGraphQL.Type.ObjectType.t),
              types: [ExGraphQL.Type.t]}

  defstruct name: nil, description: nil, resolve_type: nil, types: []

end
