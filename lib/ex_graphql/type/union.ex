defmodule ExGraphQL.Type.Union do
  defstruct name: nil, description: nil, resolveType: nil, types: []
  @type t :: %{name: binary, description: binary, resolveType: ((any, ExGraphQL.Type.ResolveInfo.t) -> any) | ((any) -> any), types: [any]}
end
