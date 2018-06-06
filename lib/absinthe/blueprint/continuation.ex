defmodule Absinthe.Blueprint.Continuation do
  @moduledoc false

  # Continuations allow further resolutions after the initial result is
  # returned

  alias Absinthe.Pipeline

  defstruct [
    :phase_input,
    :pipeline
  ]

  @type t :: %__MODULE__{
    phase_input: Pipeline.data_t,
    pipeline: Pipeline.t()
  }

end
