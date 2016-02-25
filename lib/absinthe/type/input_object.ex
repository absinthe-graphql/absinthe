defmodule Absinthe.Type.InputObject do

  use Absinthe.Introspection.Kind
  use Absinthe.Type.Fetch

  alias Absinthe.Type

  @type t :: %{name: binary, description: binary, fields: map | (() -> map), __reference__: Type.Reference.t}
  defstruct name: nil, description: nil, fields: %{}, __reference__: nil

  def build(identifier, blueprint) do
    fields = Type.Field.build_map_ast(blueprint[:fields] || [])
    quote do
      %unquote(__MODULE__){
        name: unquote(blueprint[:name]),
        fields: unquote(fields),
        description: unquote(blueprint[:description]),
        __reference__: %{
          module: __MODULE__,
          identifier: unquote(identifier),
          location: %{
            file: __ENV__.file,
            line: __ENV__.line
          }
        }
      }
    end
  end

  defimpl Absinthe.Traversal.Node do
    def children(node, _traversal) do
      Map.values(node.fields)
    end
  end

end
