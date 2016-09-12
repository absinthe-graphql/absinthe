defmodule Absinthe.Blueprint.Document.Result.Object do

  @enforce_keys [:emitter, :fields]
  defstruct [
    :emitter,
    :fields,
  ]

end
