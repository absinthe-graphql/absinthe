defmodule Absinthe.Type.SemanticNullability do
  @moduledoc """
  Support functions for semantic non-null fields.

  The `@semanticNonNull` directive allows schema authors to indicate that a field
  is semantically non-null (the resolver never intentionally returns null), but may
  still be null due to errors. This decouples nullability from error handling.

  ## Levels

  The `levels` argument specifies which levels of the return type are semantically non-null:

  - `[0]` - the field itself is semantically non-null
  - `[1]` - for list fields, the list items are semantically non-null
  - `[0, 1]` - both the field and its items are semantically non-null

  ## Example

  ```graphql
  type User {
    # This field may be null only due to errors, never intentionally
    email: String @semanticNonNull

    # The list may be null on error, but items are never intentionally null
    posts: [Post] @semanticNonNull(levels: [0, 1])
  }
  ```

  ## Usage in Elixir

  You can use this in your Absinthe schema:

  ```elixir
  object :user do
    field :email, :string do
      directive :semantic_non_null
    end

    field :posts, list_of(:post) do
      directive :semantic_non_null, levels: [0, 1]
    end
  end
  ```

  Or using the shorthand notation:

  ```elixir
  object :user do
    field :email, :string, semantic_non_null: true
    field :posts, list_of(:post), semantic_non_null: [0, 1]
  end
  ```
  """

  @doc """
  Checks if a field has the semantic non-null attribute.

  Returns `true` if the field has `@semanticNonNull` applied, `false` otherwise.

  ## Examples

      iex> Absinthe.Type.SemanticNullability.semantic_non_null?(field)
      true

  """
  @spec semantic_non_null?(Absinthe.Type.Field.t()) :: boolean()
  def semantic_non_null?(%{__private__: private}) when is_list(private) do
    Keyword.has_key?(private, :semantic_non_null)
  end

  def semantic_non_null?(_), do: false

  @doc """
  Gets the semantic non-null levels for a field.

  Returns the list of levels that are semantically non-null, or `nil` if the
  field does not have `@semanticNonNull` applied.

  ## Levels

  - `0` - the field value itself
  - `1` - items in a list (for list types)
  - `2` - items in a nested list (for list of list types)

  ## Examples

      iex> Absinthe.Type.SemanticNullability.levels(field_with_semantic_non_null)
      [0]

      iex> Absinthe.Type.SemanticNullability.levels(list_field_with_semantic_non_null)
      [0, 1]

      iex> Absinthe.Type.SemanticNullability.levels(regular_field)
      nil

  """
  @spec levels(Absinthe.Type.Field.t()) :: [non_neg_integer()] | nil
  def levels(%{__private__: private}) when is_list(private) do
    Keyword.get(private, :semantic_non_null)
  end

  def levels(_), do: nil

  @doc """
  Checks if a specific level is semantically non-null for a field.

  Returns `true` if the given level is in the list of semantic non-null levels
  for the field.

  ## Examples

      iex> Absinthe.Type.SemanticNullability.level_non_null?(field, 0)
      true

      iex> Absinthe.Type.SemanticNullability.level_non_null?(field, 1)
      false

  """
  @spec level_non_null?(Absinthe.Type.Field.t(), non_neg_integer()) :: boolean()
  def level_non_null?(field, level) when is_integer(level) and level >= 0 do
    case levels(field) do
      nil -> false
      levels -> level in levels
    end
  end

  @doc """
  Validates that the semantic non-null levels are valid for a given field type.

  Returns `:ok` if the levels are valid, or `{:error, reason}` if invalid.

  ## Validation Rules

  - Level 0 is always valid (applies to the field itself)
  - Level 1 is only valid if the field type is a list
  - Level 2 is only valid if the field type is a list of lists
  - And so on for deeper nesting

  ## Examples

      iex> Absinthe.Type.SemanticNullability.validate_levels([0], :string)
      :ok

      iex> Absinthe.Type.SemanticNullability.validate_levels([1], :string)
      {:error, "level 1 requires a list type"}

      iex> Absinthe.Type.SemanticNullability.validate_levels([0, 1], %Absinthe.Type.List{of_type: :string})
      :ok

  """
  @spec validate_levels([non_neg_integer()], any()) :: :ok | {:error, String.t()}
  def validate_levels(levels, type) when is_list(levels) do
    max_level = Enum.max(levels, fn -> 0 end)
    type_depth = get_list_depth(type)

    cond do
      max_level > type_depth ->
        {:error, "level #{max_level} requires #{max_level} nested list(s), but type only has #{type_depth}"}

      Enum.any?(levels, &(&1 < 0)) ->
        {:error, "levels must be non-negative integers"}

      true ->
        :ok
    end
  end

  def validate_levels(_, _), do: {:error, "levels must be a list of integers"}

  # Get the depth of list nesting for a type
  defp get_list_depth(%Absinthe.Type.List{of_type: inner}), do: 1 + get_list_depth(inner)
  defp get_list_depth(%Absinthe.Type.NonNull{of_type: inner}), do: get_list_depth(inner)

  defp get_list_depth(%Absinthe.Blueprint.TypeReference.List{of_type: inner}),
    do: 1 + get_list_depth(inner)

  defp get_list_depth(%Absinthe.Blueprint.TypeReference.NonNull{of_type: inner}),
    do: get_list_depth(inner)

  defp get_list_depth(_), do: 0
end
