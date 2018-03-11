defmodule Absinthe.Pipeline.ErrorResult do
  @moduledoc """
  A basic struct that wraps phase errors for
  reporting to the user.
  """

  alias Absinthe.Phase

  defstruct errors: []

  @type t :: %__MODULE__{
          errors: [Phase.Error.t()]
        }

  @doc "Generate a new ErrorResult for one or more phase errors"
  @spec new(Phase.Error.t() | [Phase.Error.t()]) :: t
  def new(errors) do
    %__MODULE__{errors: List.wrap(errors)}
  end
end
