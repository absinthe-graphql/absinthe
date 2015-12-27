defmodule Absinthe.Type.FieldDefinition do

  alias __MODULE__

  alias Absinthe.Type
  alias Absinthe.Type.Deprecation
  alias Absinthe.Schema

  @type t :: %{name: binary,
               description: binary | nil,
               type: Type.identifier_t,
               deprecation: Deprecation.t | nil,
               args: %{(binary | atom) => Absinthe.Type.Argument.t} | nil,
               resolve: ((any, %{binary => any} | nil, Absinthe.Type.ResolveInfo.t | nil) -> Absinthe.Type.output_t) | nil}

  defstruct name: nil, description: nil, type: nil, deprecation: nil, args: %{}, resolve: nil

  defimpl Absinthe.Validation.RequiredInput do

    @doc """
    Whether the field is required.

    Note this is only useful for input object types.

    * If the field is deprecated, it is never required
    * If the argumnet is not deprecated, it is required
    if its type is non-null
    """
    @spec required?(FieldDefinition.t) :: boolean
    def required?(%FieldDefinition{type: type, deprecation: nil}) do
      type
      |> Absinthe.Validation.RequiredInput.required?
    end
    def required?(%FieldDefinition{}) do
      false
    end

  end

  defimpl Absinthe.Traversal.Node do
    def children(node, traversal) do
      found = Schema.lookup_type(traversal.context, node.type)
      if found do
        [found | node.args |> Map.values]
      else
        type_names = traversal.context.types |> Map.keys |> Enum.join(", ")
        raise "Unknown Absinthe type for field `#{node.name}': (#{node.type |> Type.unwrap} not in available types, #{type_names})"
      end
    end
  end

end
