defmodule Absinthe.Blueprint.Document.Fragment do
  @moduledoc false

  alias __MODULE__

  @type t ::
          Fragment.Inline.t()
          | Fragment.Named.t()
          | Fragment.Spread.t()
end
