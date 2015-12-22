defmodule Absinthe.Type.Deprecation do

  @type t :: %{reason: binary}
  defstruct reason: nil

end
