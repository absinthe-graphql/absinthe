defmodule Absinthe.Type.Object do
  @moduledoc """
  Represents a non-leaf node in a GraphQL tree of information.

  Objects represent a list of named fields, each of which yield a value of a
  specific type. Object values are serialized as unordered maps, where the
  queried field names (or aliases) are the keys and the result of evaluating the
  field is the value.

  Also see `Absinthe.Type.Scalar`.

  ## Examples

  Given a type defined as the following (see `Absinthe.Schema.Notation.object/3`):

  ```
  @desc "A person"
  object :person do
    field :name, :string
    field :age, :integer
    field :best_friend, :person
    field :pets, list_of(:pet)
  end
  ```

  The "Person" type (referred inside Absinthe as `:person`) is an object, with
  fields that use `Absinthe.Type.Scalar` types (namely `:name` and `:age`), and
  other `Absinthe.Type.Object` types (`:best_friend` and `:pets`, assuming
  `:pet` is an object).

  Given we have a query that supports getting a person by name
  (see `Absinthe.Schema`), and a query document like the following:

  ```graphql
  {
    person(name: "Joe") {
      name
      best_friend {
        name
        age
      }
      pets {
        breed
      }
    }
  }
  ```

  We could get a result like this:

  ```
  %{
    data: %{
      "person" => %{
        "best_friend" => %{
          "name" => "Jill",
          "age" => 29
        },
        "pets" => [
          %{"breed" => "Wyvern"},
          %{"breed" => "Royal Griffon"}
        ]
      }
    }
  }
  ```
  """

  alias Absinthe.Type
  use Absinthe.Introspection.TypeKind, :object

  @typedoc """
  A defined object type.

  Note new object types (with the exception of the root-level `query`, `mutation`, and `subscription`)
  should be defined using `Absinthe.Schema.Notation.object/3`.

  * `:name` - The name of the object type. Should be a TitleCased `binary`. Set automatically.
  * `:description` - A nice description for introspection.
  * `:fields` - A map of `Absinthe.Type.Field` structs. Usually built via `Absinthe.Schema.Notation.field/4`.
  * `:interfaces` - A list of interfaces that this type guarantees to implement. See `Absinthe.Type.Interface`.
  * `:is_type_of` - A function used to identify whether a resolved object belongs to this defined type. For use with `:interfaces` entry and `Absinthe.Type.Interface`. This function will be passed one argument; the object whose type needs to be identified, and should return `true` when the object matches this type.

  The `__private__` and `:__reference__` keys are for internal use.
  """
  @type t :: %__MODULE__{
          identifier: atom,
          name: binary,
          description: binary,
          fields: map,
          interfaces: [Absinthe.Type.Interface.t()],
          __private__: Keyword.t(),
          definition: module,
          __reference__: Type.Reference.t()
        }

  defstruct identifier: nil,
            name: nil,
            description: nil,
            fields: nil,
            interfaces: [],
            __private__: [],
            definition: nil,
            __reference__: nil,
            is_type_of: nil

  @doc false
  defdelegate functions, to: Absinthe.Blueprint.Schema.ObjectTypeDefinition

  @doc false
  @spec field(t, atom) :: Absinthe.Type.Field.t()
  def field(%{fields: fields}, identifier) do
    fields
    |> Map.get(identifier)
  end
end
