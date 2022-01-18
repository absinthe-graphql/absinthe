defmodule Absinthe.Blueprint.TypeReference do
  @moduledoc false

  alias __MODULE__

  @type t ::
          TypeReference.List.t()
          | TypeReference.Name.t()
          | TypeReference.Identifier.t()
          | TypeReference.NonNull.t()

  @wrappers [TypeReference.List, TypeReference.NonNull]

  @doc """
  Unwrap a type reference from surrounding NonNull/List type information.
  """
  @spec unwrap(t) :: t
  def unwrap(%TypeReference.Name{} = value) do
    value
  end

  def unwrap(%TypeReference.Identifier{} = value) do
    value
  end

  def unwrap(value) when is_atom(value), do: value

  def unwrap(%struct{of_type: inner}) when struct in @wrappers do
    unwrap(inner)
  end

  @doc """
  Get the GraphQL name for a (possibly wrapped) type reference.

  """
  def name(%__MODULE__.NonNull{of_type: type}) do
    name(type) <> "!"
  end

  def name(%__MODULE__.List{of_type: type}) do
    "[" <> name(type) <> "]"
  end

  def name(%__MODULE__.Name{name: name}) do
    name
  end

  def to_type(%__MODULE__.NonNull{of_type: type}, schema) do
    %Absinthe.Type.NonNull{of_type: to_type(type, schema)}
  end

  def to_type(%__MODULE__.List{of_type: type}, schema) do
    %Absinthe.Type.List{of_type: to_type(type, schema)}
  end

  def to_type(%__MODULE__.Name{name: name}, schema) do
    Enum.find(schema.type_definitions, &(&1.name == name)).identifier
  end

  def to_type(%__MODULE__.Identifier{id: id}, _) when is_atom(id) do
    id
  end

  def to_type(value, _) when is_atom(value) do
    value
  end
end
