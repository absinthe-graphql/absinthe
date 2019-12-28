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

  @typedoc """
  Note new input object types should be defined using
  `Absinthe.Schema.Notation.input_object/3`.

  * `:name` - The name of the input object type. Should be a TitleCased `binary`. Set automatically.
  * `:description` - A nice description for introspection.
  * `:fields` - A map of `Absinthe.Type.Field` structs. Usually built via `Absinthe.Schema.Notation.field/4`.

  The `__private__` and `:__reference__` fields are for internal use.
  """
  @type t :: %__MODULE__{
          name: binary,
          description: binary,
          fields: map,
          identifier: atom,
          __private__: Keyword.t(),
          definition: module,
          __reference__: Type.Reference.t()
        }

  defstruct name: nil,
            description: nil,
            fields: %{},
            identifier: nil,
            __private__: [],
            definition: nil,
            __reference__: nil
end
