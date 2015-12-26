defmodule Absinthe.Schema do

  defmacro __using__(options) do
    type_modules = options |> Keyword.get(:type_modules, [])
    quote do
      @behaviour unquote(__MODULE__)

      def mutation, do: nil

      def subscription, do: nil

      defoverridable [mutation: 0,
                      subscription: 0]

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

  @typep required_object_t :: Absinthe.Type.ObjectType.t
  @typep optional_object_t :: Absinthe.Type.ObjectType.t | nil

  @doc """
  Define the query root type
  """
  @callback query :: required_object_t

  @doc """
  Define the mutation root type
  """
  @callback mutation :: optional_object_t

  @doc """
  Define the subscription root type
  """
  @callback subscription :: optional_object_t

  alias Absinthe.Type
  alias Absinthe.Language
  alias __MODULE__

  @type t :: %{query: required_object_t,
               mutation: optional_object_t,
               subscription: optional_object_t,
               type_modules: [atom],
               types: Schema.Types.typemap_t,
               errors: [binary]}

  defstruct query: nil, mutation: nil, subscription: nil, type_modules: [], types: %{}, errors: []

  @doc "Add types (but only do it once; if any have been found, this is just an identity function)"
  @spec prepare(t) :: t
  def prepare(%{types: types} = schema) when map_size(types) == 0 do
    schema
    |> Schema.Types.setup
  end
  def prepare(schema) do
    schema
  end

  @doc "Lookup a type that in used by/available to a schema"
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

  defimpl Absinthe.Traversal.Node do

    def children(node, _) do
      [node.query, node.mutation, node.subscription]
      |> Enum.reject(&is_nil/1)
    end

  end


end
