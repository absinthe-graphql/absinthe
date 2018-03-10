defmodule Absinthe.Phase.Error do
  @moduledoc false

  @enforce_keys [:message, :phase]
  defstruct [
    :message,
    :phase,
    locations: [],
    extra: %{},
    path: []
  ]

  @type loc_t :: %{optional(any) => any, line: integer, column: nil | integer}

  @type t :: %__MODULE__{
          message: String.t(),
          phase: module,
          locations: [loc_t],
          path: [],
          extra: map
        }
end
