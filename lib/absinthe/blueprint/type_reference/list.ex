defmodule Absinthe.Blueprint.TypeReference.List do
  @moduledoc false

  alias Absinthe.Blueprint

  @enforce_keys [:of_type]
  defstruct [
    :of_type,
    errors: []
  ]

  @type t :: %__MODULE__{
          of_type: Blueprint.TypeReference.t(),
          errors: [Absinthe.Phase.Error.t()]
        }
end
