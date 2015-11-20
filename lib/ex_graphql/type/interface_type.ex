defmodule ExGraphQL.Type.InterfaceType do
  @type t :: %{name: binary, description: binary, fields: map, resolve_type: ((any, ExGraphQL.Type.ResolveInfo.t) -> ExGraphQL.Type.ObjectType.t)}
  defstruct name: nil, description: nil, fields: nil, resolve_type: nil
end
