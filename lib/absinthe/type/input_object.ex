defmodule Absinthe.Type.InputObject do

  use Absinthe.Introspection.Kind
  use Absinthe.Type.Fetch

  alias Absinthe.Type

  @type t :: %{name: binary, description: binary, fields: map | (() -> map), reference: Type.Reference.t}
  defstruct name: nil, description: nil, fields: %{}, reference: nil

  defimpl Absinthe.Traversal.Node do
    def children(node, _traversal) do
      Map.values(node.fields)
    end
  end

end
