defmodule Absinthe.Blueprint.TypeReference.Name do
  @moduledoc false

  alias Absinthe.Phase

  @enforce_keys [:name]
  defstruct [
    :name,
    :schema_node,
    errors: []
  ]

  @type t :: %__MODULE__{
          name: String.t(),
          errors: [Phase.Error.t()]
        }
end
