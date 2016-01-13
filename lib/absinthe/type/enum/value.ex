defmodule Absinthe.Type.Enum.Value do

  alias Absinthe.Type

  @type t :: %{name: binary, description: binary, value: any, deprecation: Type.Deprecation.t | nil}
  defstruct name: nil, description: nil, value: nil, deprecation: nil
end
