defmodule Absinthe.Blueprint.Document.Result do

  alias Absinthe.Phase
  alias __MODULE__

  defstruct [
    validation: [],
    resolution: nil
  ]

  def new do
    %__MODULE__{}
  end

  @type t :: %__MODULE__ {
    validation: [Phase.Error.t],
    resolution: nil | Result.Object.t
  }

  @type node_t ::
      Result.Object
    | Result.List
    | Result.Leaf

end
