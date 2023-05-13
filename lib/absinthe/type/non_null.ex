defmodule Absinthe.Type.NonNull do
  @moduledoc """
  A type that wraps an underlying type, acting identically to that type but
  adding a non-null constraint.

  By default, all types in GraphQL are nullable. To declare a type that
  disallows null, wrap it in a `Absinthe.Type.NonNull` struct.

  Adding non_null/1 to a type is a breaking change, removing it is not. Client documents that specify non null on a
  variable eg `query ($id: ID!)` are allowed to be passed to arguments which allow null. If the argument however is
  non_null, then the variable type MUST be non null as well.

  ## Examples

  Given a type, `:item`, to declare it as non-null, you could do the following:

  ```
  type: %Absinthe.Type.NonNull{of_type: :item}
  ```

  But normally this would be done using `Absinthe.Schema.Notation.non_null/1`.

  ```
  type: non_null(:item)
  ```
  """

  use Absinthe.Introspection.TypeKind, :non_null

  @typedoc """
  A defined non-null type.

  ## Options

  * `:of_type` -- the underlying type to wrap
  """
  defstruct of_type: nil

  @type t :: %__MODULE__{of_type: Absinthe.Type.nullable_t()}
  @type t(x) :: %__MODULE__{of_type: x}
end
