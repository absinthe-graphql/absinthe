defmodule Absinthe.Type.List do
  @type t :: %{of_type: Absinthe.Type.t}
  defstruct of_type: nil
end
