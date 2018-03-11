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

  ```
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
  use Absinthe.Introspection.Kind

  @typedoc """
  A defined object type.

  Note new object types (with the exception of the root-level `query`, `mutation`, and `subscription`)
  should be defined using `Absinthe.Schema.Notation.object/3`.

  * `:name` - The name of the object type. Should be a TitleCased `binary`. Set automatically.
  * `:description` - A nice description for introspection.
  * `:fields` - A map of `Absinthe.Type.Field` structs. Usually built via `Absinthe.Schema.Notation.field/1`.
  * `:interfaces` - A list of interfaces that this type guarantees to implement. See `Absinthe.Type.Interface`.
  * `:is_type_of` - A function used to identify whether a resolved object belongs to this defined type. For use with `:interfaces` entry and `Absinthe.Type.Interface`.

  The `__private__` and `:__reference__` keys are for internal use.
  """
  @type t :: %__MODULE__{
          identifier: atom,
          name: binary,
          description: binary,
          fields: map,
          interfaces: [Absinthe.Type.Interface.t()],
          is_type_of: (any -> boolean),
          __private__: Keyword.t(),
          __reference__: Type.Reference.t()
        }

  defstruct identifier: nil,
            name: nil,
            description: nil,
            fields: nil,
            interfaces: [],
            is_type_of: nil,
            __private__: [],
            __reference__: nil,
            field_imports: []

  def build(%{attrs: attrs}) do
    fields =
      (attrs[:fields] || [])
      |> Type.Field.build()
      |> handle_imports(attrs[:field_imports])

    attrs = Keyword.put(attrs, :fields, fields)

    quote do
      %unquote(__MODULE__){
        unquote_splicing(attrs)
      }
    end
  end

  @doc false
  def handle_imports(fields, []), do: fields
  def handle_imports(fields, nil), do: fields

  def handle_imports(fields, imports) do
    quote do
      Enum.reduce(
        unquote(imports),
        unquote(fields),
        &Absinthe.Type.Object.import_fields(__MODULE__, &1, &2)
      )
    end
  end

  def import_fields(schema, {type, _opts}, fields) do
    case schema.__absinthe_type__(type) do
      %{fields: new_fields} ->
        Map.merge(fields, new_fields)

      _ ->
        fields
    end
  end

  @doc false
  @spec field(t, atom) :: Absinthe.Type.Field.t()
  def field(%{fields: fields}, identifier) do
    fields
    |> Map.get(identifier)
  end

  defimpl Absinthe.Traversal.Node do
    def children(node, _traversal) do
      Map.values(node.fields) ++ node.interfaces
    end
  end
end
