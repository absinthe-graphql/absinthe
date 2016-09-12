defmodule Absinthe.Blueprint.Document.Result.Leaf do

  @enforce_keys [:emitter, :value]
  defstruct [
    :emitter,
    :value
  ]

end
