defmodule Absinthe.Schema do
  alias Absinthe.Utils
  import Absinthe.Schema.TypeModule

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

  Now, define a `query` (and optionally, `mutation`
  and `subscription`).

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

  query [
    fields: [
      item: [
        type: :item,
        description: "Get an item by ID",
        args: [
          id: [type: :id, description: "The ID of the item"]
        ],
        resolve: fn
          %{id: id}, _ ->
            {:ok, Map.get(@fake_db, id)}
        end
      ]
    ]
  ]
  ```

  For more information on object types (especially how the `resolve`
  function works above), see `Absinthe.Type.Object`.

  You may also notice we've declared that the resolved value of the field
  to be of `type: :item`. We now need to define exactly what an `:item` is,
  and what fields it contains.

  ```
  @doc \"""
  A valuable item
  \"""
  object :item, [
    fields: [
      id: [type: :id],
      name: [type: :string, description: "The item's name"],
      value: [type: :integer, description: "Recently appraised value"]
    ]
  ]
  ```

  We can also load types from other modules using the `import_types`
  macro:

  ```
  defmodule App.Schema do

    use Absinthe.Schema

    import_types App.Schema.Scalars
    import_types App.Schema.Objects

    # ... schema definition

  end
  ```

  Our `:item` type above could then move into `App.Schema.Objects`:

  ```
  defmodule App.Schema.Objects do

    use Absinthe.Scheme.TypeModule

    object :item, [
      # ... type definition
    ]

    # ... other objects!

  end
  ```
  """

  @typedoc """
  A module defining a schema.
  """
  @type t :: atom

  alias Absinthe.Type
  alias Absinthe.Language
  alias __MODULE__

  defmacro __using__(opts) do
    quote do
      use Absinthe.Schema.TypeModule
      import unquote(__MODULE__)
      import_types Absinthe.Type.BuiltIns, export: false
      @after_compile unquote(__MODULE__)
    end
  end

  def __after_compile__(env, _bytecode) do
    [
      env.module.__absinthe_errors__,
      Schema.Problems.ReservedNames.from(env.module)
    ]
    |> List.flatten
    |> case do
      [] ->
        nil
      problems ->
        raise Absinthe.Schema.Error, problems
    end
  end

  defmacro query(name, blueprint) when is_binary(name) do
    quote do
      object [query: unquote(name)], unquote(blueprint), export: false
    end
  end
  defmacro query(blueprint) do
    quote do
      query "RootQueryType", unquote(blueprint)
    end
  end

  defmacro mutation(name, blueprint) when is_binary(name) do
    quote do
      object [mutation: unquote(name)], unquote(blueprint), export: false
    end
  end
  defmacro mutation(blueprint) do
    quote do
      mutation "RootMutationType", unquote(blueprint)
    end
  end

  defmacro subscription(name, blueprint) when is_binary(name) do
    quote do
      object [subscription: unquote(name)], unquote(blueprint), export: false
    end
  end
  defmacro subscription(blueprint) do
    quote do
      subscription "RootSubscriptionType", unquote(blueprint)
    end
  end

  # Lookup a directive that in used by/available to a schema
  @doc """
  Lookup a directive.
  """
  @spec lookup_directive(t, atom | binary) :: Type.Directive.t | nil
  def lookup_directive(schema, name) do
    schema.__absinthe_directive__(name)
  end

  @doc """
  Lookup a type by name, identifier, or by unwrapping.
  """
  @spec lookup_type(atom, Type.wrapping_t | Type.t | Type.identifier_t, Keyword.t) :: Type.t | nil
  def lookup_type(schema, type, options \\ [unwrap: true]) do
    cond do
      Type.wrapped?(type) ->
        if Keyword.get(options, :unwrap) do
          lookup_type(schema, type |> Type.unwrap)
        else
          type
        end
      is_atom(type) ->
        schema.__absinthe_type__(type)
      is_binary(type) ->
        schema.__absinthe_type__(type)
      true ->
        type
    end
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
    schema.__absinthe_types__
    |> Map.values
    |> Enum.find(:name, fn
      %{name: name} ->
        name == ast_type.name
    end)
  end

end
