defmodule Absinthe.Schema do

  defmacro __using__(_) do
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
        |> Map.merge(%{source_module: __MODULE__})
        struct(unquote(__MODULE__), contents)
        |> unquote(__MODULE__).prepare
      end

      use Absinthe.Type.Definitions

    end
  end

  @doc """
  Define the query root type
  """
  @callback query :: Absinthe.Type.ObjectType.t

  @doc """
  Define the mutation root type
  """
  @callback mutation :: Absinthe.Type.ObjectType.t | nil

  @doc """
  Define the subscription root type
  """
  @callback subscription :: Absinthe.Type.ObjectType.t | nil

  alias Absinthe.Type
  alias Absinthe.Language
  alias __MODULE__

  @type t :: %{query: Type.ObjectType.t | nil,
               mutation: Type.ObjectType.t | nil,
               subscription: Type.ObjectType.t | nil,
               source_module: atom,
               types_available: map,
               types_used: map}

  defstruct query: nil, mutation: nil, subscription: nil, source_module: nil, types_available: %{}, types_used: %{}

  @doc "Add types (but only do it once; if any have been found, this is just an identity function)"
  @spec prepare(t) :: t
  def prepare(%{types_used: types_used} = schema) when map_size(types_used) == 0 do
    schema_with_types_available = %{schema | types_available: Type.available_types([schema.source_module])}
    types_used = Schema.TypesUsed.calculate(schema_with_types_available)
    %{schema_with_types_available | types_used: types_used}
  end
  def prepare(schema) do
    schema
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
    schema.types_used
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
