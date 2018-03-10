defmodule Absinthe.Blueprint.Input.Variable do
  @moduledoc false

  alias __MODULE__
  alias Absinthe.{Blueprint, Phase}

  @enforce_keys [:name]
  defstruct [
    :name,
    source_location: nil,
    # Added by phases
    flags: %{},
    errors: []
  ]

  @type t :: %__MODULE__{
          name: String.t(),
          source_location: nil | Blueprint.Document.SourceLocation.t(),
          # Added by phases
          flags: Blueprint.flags_t(),
          errors: [Phase.Error.t()]
        }

  @doc """
  Generate a use reference for a variable.
  """
  @spec to_use(t) :: Variable.Use.t()
  def to_use(%__MODULE__{} = node) do
    %Variable.Use{
      name: node.name,
      source_location: node.source_location
    }
  end
end
