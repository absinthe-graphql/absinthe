defmodule Absinthe.Blueprint.Document.Result.List do

  @enforce_keys [:emitter, :values]
  defstruct [
    :emitter,
    :values
  ]

end
