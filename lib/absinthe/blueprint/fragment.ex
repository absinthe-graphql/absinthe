defmodule Absinthe.Blueprint.Fragment do

  alias __MODULE__

  @type t ::
      Fragment.Inline
    | Fragment.Named
    | Fragment.Spread

end
