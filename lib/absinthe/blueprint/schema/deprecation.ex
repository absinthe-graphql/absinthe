defmodule Absinthe.Blueprint.Schema.Deprecation do
  @moduledoc false

  defstruct reason: nil

  @type t :: %__MODULE__{
          reason: nil | String.t()
        }
end
