defmodule Absinthe.Blueprint.TypeReference.Identifier do
  @moduledoc false

  alias Absinthe.Phase

  @enforce_keys [:id]
  defstruct [
    :id,
    :schema_node,
    errors: []
  ]

  @type t :: %__MODULE__{
          id: any(),
          errors: [Phase.Error.t()]
        }
end
