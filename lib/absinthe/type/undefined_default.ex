defmodule Absinthe.Type.UndefinedDefault do
  @moduledoc false

  @typedoc """
  Definition to undefined default values.
  """

  @type t :: %__MODULE__{
    empty: binary
  }

  defstruct empty: "undefined"
end
