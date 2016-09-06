defmodule Absinthe.Blueprint.Input.Variable do

  alias __MODULE__
  alias Absinthe.{Blueprint, Phase}

  @enforce_keys [:name]
  defstruct [
    :name,
    source_location: nil,
    # Added by phases
    flags: [],
    errors: [],
  ]

  @type t :: %__MODULE__{
    name: String.t,
    source_location: nil | Blueprint.Document.SourceLocation.t,
    # Added by phases
    flags: [atom],
    errors: [Phase.Error.t],
  }

  @doc """
  Generate a reference to a variable
  """
  @spec to_reference(t) :: Variable.Reference.t
  def to_reference(%__MODULE__{} = var) do
    %Variable.Reference{
      name: var.name,
      source_location: var.source_location
    }
  end

end
