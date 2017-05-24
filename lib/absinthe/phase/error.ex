defmodule Absinthe.Phase.Error do

  @moduledoc false

  @enforce_keys [:message, :phase]
  defstruct [
    :message,
    :phase,
    locations: [],
    extra: %{}
  ]

  @type loc_t :: %{optional(any) => any, line: integer, column: nil | integer}

  @type t :: %__MODULE__{
    message: String.t,
    phase: module,
    locations: [loc_t],
    extra: map
  }

  @type option :: {:location, loc_t | [loc_t]} | {:extra, map | Keyword.t}
  @type options:: [option]

  @doc """
  Generate a phase error.
  If it is relates to a specific point in the document the option
  `location` can be used.
  The error can contain extra information using the `extra` option.
  """
  @spec new(Absinthe.Phase.t, String.t) :: t
  @spec new(Absinthe.Phase.t, String.t, options) :: t
  def new(phase, message, opts \\ []) do
    %__MODULE__{
      phase: phase,
      message: message,
      locations: List.wrap(Keyword.get(opts, :location, [])),
      extra: Map.new(Keyword.get(opts, :extra, []))
    }
  end

end
