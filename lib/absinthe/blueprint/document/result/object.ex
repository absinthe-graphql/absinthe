defmodule Absinthe.Blueprint.Document.Result.Object do

  @enforce_keys [:name, :fields]
  defstruct [
    :name,
    :fields,
  ]

end
