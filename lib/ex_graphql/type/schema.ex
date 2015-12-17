defmodule ExGraphQL.Type.Schema do
  @type t :: %{query:        ExGraphQL.Type.ObjectType.t | nil,
               mutation:     ExGraphQL.Type.ObjectType.t | nil,
               subscription: ExGraphQL.Type.ObjectType.t | nil,
               type_map:     map}
  defstruct query: nil, mutation: nil, subscription: nil, type_map: %{}

  alias ExGraphQL.Type
  alias ExGraphQL.Language

  @doc "Add types (but only do it once; if any have been found, this is just an identity function)"
  @spec with_type_map(t) :: t
  def with_type_map(%{type_map: type_map} = schema) when map_size(type_map) == 0 do
    %{schema | type_map: Type.TypeMap.build(schema)}
  end
  def with_type_map(%{type_map: type_map} = schema) do
    schema
  end

  @spec type_from_ast(t, Language.type_reference_t) :: ExGraphQL.Type.t | nil
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
    name = ast_type.name
    schema
    |> with_type_map
    |> Map.get(:type_map)
    |> Map.get(name)
  end

end
