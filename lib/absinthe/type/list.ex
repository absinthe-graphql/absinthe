defmodule Absinthe.Type.List do
  @moduledoc """
  A wrapping type which declares the type of each item in the list.

  ## Examples

  Given a type, `:item`, to declare the type of a field/argument as a list of
  `:item`-typed values, you could do:

  ```
  type: %Absinthe.Type.List{of_type: :item}
  ```

  But normally this would be done using `Absinthe.Schema.Notation.list_of/1`.

  ```
  type: list_of(:item)
  ```
  """

  use Absinthe.Introspection.Kind
  use Absinthe.Type.Fetch

  @typedoc "
  A defined list type.

  ## Options

  * `:of_type` - The underlying, wrapped type.
 "
  @type t :: %__MODULE__{of_type: Absinthe.Type.t()}
  defstruct of_type: nil
end
