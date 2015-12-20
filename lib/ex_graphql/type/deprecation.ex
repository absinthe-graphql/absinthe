defmodule ExGraphQL.Type.Deprecation do

  @type t :: %{reason: binary}
  defstruct reason: nil

end
