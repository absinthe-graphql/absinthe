defmodule Absinthe.Blueprint.Document.Fragment do

  @moduledoc false

  alias __MODULE__

  @type t ::
      Fragment.Inline
    | Fragment.Named
    | Fragment.Spread

end
