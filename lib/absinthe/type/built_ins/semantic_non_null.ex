defmodule Absinthe.Type.BuiltIns.SemanticNonNull do
  @moduledoc """
  Proposed-spec @semanticNonNull directive.

  This directive is part of the [GraphQL Nullability Working Group](https://github.com/graphql/nullability-wg)
  proposal and is not yet part of the finalized GraphQL specification.

  ## Usage

  To enable @semanticNonNull in your schema, import this module:

      defmodule MyApp.Schema do
        use Absinthe.Schema

        import_types Absinthe.Type.BuiltIns.SemanticNonNull

        query do
          # ...
        end
      end

  Then you can use the directive on field definitions:

      object :user do
        field :id, non_null(:id)

        # This field is semantically non-null - it only returns null on errors
        field :name, :string do
          directive :semantic_non_null
        end
      end

  ## Purpose

  The @semanticNonNull directive decouples nullability from error handling. It indicates
  that a field's resolver never intentionally returns null, but null may still be returned
  due to errors. This allows clients to understand which fields may be null only due to
  errors versus fields that may intentionally be null.

  ## Arguments

  - `levels` - Specifies which levels of the return type are semantically non-null:
    - `[0]` (default) - The field itself is semantically non-null
    - `[1]` - For list fields, the list items are semantically non-null
    - `[0, 1]` - Both the field and its items are semantically non-null
  """

  use Absinthe.Schema.Notation

  directive :semantic_non_null do
    description """
    Indicates that a field is semantically non-null: the resolver never intentionally returns null,
    but null may still be returned due to errors.

    This decouples nullability from error handling, allowing clients to understand which fields
    may be null only due to errors versus fields that may intentionally be null.
    """

    arg :levels, non_null(list_of(non_null(:integer))),
      default_value: [0],
      description: """
      Specifies which levels of the return type are semantically non-null.
      - [0] means the field itself is semantically non-null
      - [1] for list fields means the list items are semantically non-null
      - [0, 1] means both the field and its items are semantically non-null
      """

    repeatable false
    on [:field_definition]

    expand(fn args, node ->
      levels = Map.get(args, :levels, [0])
      %{node | __private__: Keyword.put(node.__private__, :semantic_non_null, levels)}
    end)
  end
end
