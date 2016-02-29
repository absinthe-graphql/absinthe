defmodule Absinthe.Type.InputObject do
  @moduledoc """
  Defines a GraphQL input object

  Input objects enable nested arguments to queries and mutations.

  ## Example

  ```
  mutation do
    field :user, :user do
      arg :name, :string
      arg :contact, non_null(:contact)

      resolve &User.create/2
    end
  end

  input_object :contact do
    field :email, :string
  end
  ```

  This supports the following `mutation`:
  ```graphql
  mutation CreateUser {
    user(contact: {email: "foo@bar.com"}) {
      id
    }
  }
  ```
  """

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
