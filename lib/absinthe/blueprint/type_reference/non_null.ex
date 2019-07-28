defmodule Absinthe.Blueprint.TypeReference.NonNull do
  @moduledoc false

  alias Absinthe.{Blueprint, Phase}

  @enforce_keys [:of_type]
  defstruct [
    :of_type,
    errors: []
  ]

  @type t :: %__MODULE__{
          of_type: Blueprint.TypeReference.t(),
          errors: [Phase.Error.t()]
        }
end
