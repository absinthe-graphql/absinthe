defmodule Absinthe.Type.NonNull do
  @type t :: %{of_type: Absinthe.Type.nullable_t}
  defstruct of_type: nil
end
