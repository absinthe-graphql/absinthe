defmodule Absinthe.Blueprint.Document.Result.Leaf do

  @enforce_keys [:name, :value]
  defstruct [
    :name,
    :value
  ]

end
