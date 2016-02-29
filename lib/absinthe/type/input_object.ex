defmodule Absinthe.Type.InputObject do

  use Absinthe.Introspection.Kind
  use Absinthe.Type.Fetch

  alias Absinthe.Type

  @type t :: %{name: binary, description: binary, fields: map | (() -> map), __reference__: Type.Reference.t}
  defstruct name: nil, description: nil, fields: %{}, __reference__: nil

  def build(%{attrs: attrs}) do
    fields = Type.Field.build(attrs[:fields] || [])
    quote do: %unquote(__MODULE__){unquote_splicing(attrs), fields: unquote(fields)}
  end

  defimpl Absinthe.Traversal.Node do
    def children(node, _traversal) do
      Map.values(node.fields)
    end
  end

end
