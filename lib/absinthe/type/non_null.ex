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

  But normally this would be done using the `Absinthe.Type.Definitions.non_null/1`
  convenience function:

  ```
  type: non_null(:item)
  ```
  """

  @typedoc """
  A defined non-null type.

  ## Options

  * `:of_type` -- the underlying type to wrap
  """
  @type t :: %{of_type: Absinthe.Type.nullable_t}
  defstruct of_type: nil
end
