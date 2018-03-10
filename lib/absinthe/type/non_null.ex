defmodule Absinthe.Type.NonNull do
  @moduledoc """
  A type that wraps an underlying type, acting identically to that type but
  adding a non-null constraint.

  By default, all types in GraphQL are nullable. To declare a type that
  disallows null, wrap it in a `Absinthe.Type.NonNull` struct.

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

  use Absinthe.Introspection.Kind
  use Absinthe.Type.Fetch

  @typedoc """
  A defined non-null type.

  ## Options

  * `:of_type` -- the underlying type to wrap
  """
  defstruct of_type: nil

  @type t :: %__MODULE__{of_type: Absinthe.Type.nullable_t()}
  @type t(x) :: %__MODULE__{of_type: x}
end
