defmodule Absinthe.Phase.Error do

  @moduledoc false

  @enforce_keys [:message, :phase]
  defstruct [
    :message,
    :phase,
    locations: [],
    extra: []
  ]

  @type loc_t :: %{line: integer, column: nil | integer}

  @type t :: %__MODULE__{
    message: String.t,
    phase: module,
    locations: [loc_t],
    extra: Keyword.t
  }

  @doc """
  Generate a phase error that relates to a specific point in the
  document.
  """
  @spec new(Absinthe.Phase.t, String.t, loc_t | [loc_t]) :: t
  @spec new(Absinthe.Phase.t, String.t, loc_t | [loc_t], Keyword.t) :: t
  def new(phase, message, location, extra \\ []) do
    %__MODULE__{
      phase: phase,
      message: message,
      locations: List.wrap(location),
      extra: extra
    }
  end

  @doc """
  Generate a phase error that doesn't relate to a specific point in the
  document.
  """
  @spec new(Absinthe.Phase.t, String.t) :: t
  def new(phase, message) do
    %__MODULE__{
      phase: phase,
      message: message
    }
  end

end
