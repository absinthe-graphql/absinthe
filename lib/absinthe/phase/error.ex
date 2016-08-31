defmodule Absinthe.Phase.Error do

  @enforce_keys [:message, :phase]
  defstruct [
    :message,
    :phase,
    locations: []
  ]

  @type loc_t :: %{line: integer, column: nil | integer}

  @type t :: %__MODULE__{
    message: String.t,
    phase: module,
    locations: [loc_t],
  }

  @spec new(Absinthe.Phase.t, String.t, loc_t | [loc_t]) :: t
  def new(phase, message, location) do
    %__MODULE__{
      phase: phase,
      message: message,
      locations: List.wrap(location)
    }
  end

end
