defmodule Absinthe.Type.InputObject do

  use Absinthe.Introspection.Kind
  use Absinthe.Type.Fetch

  alias Absinthe.Type

  @type t :: %{name: binary, description: binary, fields: map | (() -> map), reference: Type.Reference.t}
  defstruct name: nil, description: nil, fields: %{}, reference: nil

  def build([{identifier, name}], blueprint) do
    fields = Type.Field.build_map_ast(blueprint[:fields] || [])
    quote do
      %unquote(__MODULE__){
        name: unquote(name),
        fields: unquote(fields),
        description: @absinthe_doc,
        reference: %{
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
