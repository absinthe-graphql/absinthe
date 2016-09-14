defmodule Absinthe.Blueprint.Document.Result do

  alias __MODULE__

  @type t ::
      Result.Object
    | Result.List
    | Result.Leaf

end
