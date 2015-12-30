defmodule Absinthe.Schema do

  @moduledoc """
  Define a GraphQL schema.

  ## Basic Usage

  To define a schema, `use Absinthe.Schema` within
  a module. This marks your module as adhering to the
  `Absinthe.Schema` behaviour, and sets up some macros
  and utility functions for your use:

  ```
  defmodule App.Schema do

    use Absinthe.Schema

    # ... define it here!

  end
  ```

  Now, define a `query` function (and optionally, `mutation`
  and `subscription`) functions. These should return the _root_
  objects for each of those operations.

  We'll define a `query` that has one field, `item`, to support
  querying for an item record by its ID:

  ```
  # Just for the example. You're probably using Ecto or
  # something much more interesting than a module attribute-based
  # database!
  @fake_db %{
    "foo" => %{id: "foo", name: "Foo", value: 4},
    "bar" => %{id: "bar", name: "Bar", value: 5}
  }

  def query do
    %Absinthe.Type.ObjectType{
      fields: fields(
        item: [
          type: :item,
          description: "Get an item by ID",
          args: args(
            id: [type: :id, description: "The ID of the item"]
          ),
          resolve: fn %{id: id}, _ ->
            {:ok, Map.get(@fake_db, id)}
          end
        ]
      )
    }
  end
  ```

  We use `Absinthe.Type.Definitions.fields/1` and
  `Absinthe.Type.Definitions.args/1` here, available automatically because
  of the `use Absinthe.Schema` at the top of our module. These are
  convenience functions that ease compact, readable definitions for fields
  and arguments.

  For more information on object types (especially how the `resolve`
  function works above), see `Absinthe.Type.ObjectType`.

  You may also notice we've declared that the resolved value of the field
  to be of `type: :item`. We now need to define exactly what an `:item` is,
  and what fields it contains.

  Thankfully another `Absinthe.Type.Definitions` utility can be used to do this
  easily, and inside our schema module. We just need to set the `@absinthe`
  module attribute before a function that returns an object type:

  ```
  @absinthe :type
  def item do
    %Absinthe.Type.ObjectType{
      description: "A valuable item",
      fields: fields(
        id: [type: :id],
        name: [type: :string, description: "The item's name"],
        value: [type: :integer, description: "Recently appraised value"]
      )
    }
  end
  ```

  (You can read more about building custom types and the available
  convenience functions in `Absinthe.Type.Definitions` --
  and check out `Absinthe.Type.Scalar`, where the built-in types like
  `:integer`, `:id`, and `:string` are defined.)

  Our schema is now ready to be executed (using, eg, `Absinthe.run/2`).
  """

  defmacro __using__(options) do
    type_modules = options |> Keyword.get(:type_modules, [])
    quote do
      @behaviour unquote(__MODULE__)

      def mutation, do: nil

      def subscription, do: nil

      defoverridable [mutation: 0,
                      subscription: 0]

      @doc """
      Build the configured schema struct.

      This uses functions implementing the callbacks for
      the `Abinthe.Schema` behaviour. You should never
      need to create a schema struct manually.
      """
      def schema do
        contents = [
          query: query,
          mutation: mutation,
          subscription: subscription
        ]
        |> Enum.filter(fn
          {_, nil} -> false
          other -> true
        end)
        |> Enum.into(%{})
        |> Map.merge(%{type_modules: [__MODULE__] ++ unquote(type_modules)})
        struct(unquote(__MODULE__), contents)
        |> unquote(__MODULE__).prepare
      end

      use Absinthe.Type.Definitions

    end
  end

  @doc """
  (Required) Define the query root type.

  Should be an `Absinthe.Type.ObjectType` struct.
  """
  @callback query :: Absinthe.Type.ObjectType.t

  @doc """
  (Optional) Define the mutation root type.

  Should be an `Absinthe.Type.ObjectType` struct.
  """
  @callback mutation :: nil | Absinthe.Type.ObjectType.t

  @doc """
  (Optional) Define the subscription root type.

  Should be an `Absinthe.Type.ObjectType` struct.
  """
  @callback subscription :: nil | Absinthe.Type.ObjectType.t

  alias Absinthe.Type
  alias Absinthe.Language
  alias __MODULE__

  @typedoc """
  A struct containing the defined schema details.

  Don't create these structs yourself. Just define
  the necessary `Absinthe.Schema` callbacks and
  use `schema/0`
  """
  @type t :: %{query: Absinthe.Type.ObjectType.t,
               mutation: nil | Absinthe.Type.ObjectType.t,
               subscription: nil | Absinthe.Type.ObjectType.t,
               type_modules: [atom],
               types: Schema.Types.typemap_t,
               errors: [binary]}

  defstruct query: nil, mutation: nil, subscription: nil, type_modules: [], types: %{}, errors: []

  # Add types (but only do it once; if any have been found, this is just an identity function)
  @doc false
  @spec prepare(t) :: t
  def prepare(%{types: types} = schema) when map_size(types) == 0 do
    schema
    |> Schema.Types.setup
  end
  def prepare(schema) do
    schema
  end

  # Lookup a type that in used by/available to a schema
  @doc false
  @spec lookup_type(t, Type.wrapping_t | Type.t | Type.identifier_t) :: Type.t | nil
  def lookup_type(schema, type) when is_map(type) do
    if Type.wrapped?(type) do
      lookup_type(schema, type |> Type.unwrap)
    else
      type
    end
  end
  def lookup_type(schema, identifier) do
    schema.types[identifier]
  end

  @doc false
  @spec type_from_ast(t, Language.type_reference_t) :: Absinthe.Type.t | nil
  def type_from_ast(schema, %Language.NonNullType{type: inner_type}) do
    case type_from_ast(schema, inner_type) do
      nil -> nil
      type -> %Type.NonNull{of_type: type}
    end
  end
  def type_from_ast(schema, %Language.ListType{type: inner_type}) do
    case type_from_ast(schema, inner_type) do
      nil -> nil
      type -> %Type.List{of_type: type}
    end
  end
  def type_from_ast(schema, ast_type) do
    schema.types
    |> Map.values
    |> Enum.find(:name, fn
      %{name: name} ->
        name == ast_type.name
    end)
  end

  @doc """
  Verify that a schema is correctly formed

  ## Examples

  `{:ok, schema}` is returned if the schema is free of errors:

  ```
  {:ok, schema} = Absinthe.Schema.verify(App.GoodSchema)
  ```

  Otherwise the errors are returned in a tuple:

  ```
  {:error, errors} = Absinthe.Schema.verify(App.BadSchema)
  ```

  """
  @spec verify(atom | t) :: {:ok, t}  | {:error, [binary]}
  def verify(name) when is_atom(name) do
    verify(name.schema)
  end
  def verify(%Schema{errors: errors} = schema) when length(errors) > 0 do
    {:error, errors}
  end
  def verify(%Schema{} = schema) do
    {:ok, schema}
  end

  defimpl Absinthe.Traversal.Node do

    def children(node, _) do
      [node.query, node.mutation, node.subscription]
      |> Enum.reject(&is_nil/1)
    end

  end


end
