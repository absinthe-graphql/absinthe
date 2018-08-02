defmodule Absinthe.Blueprint.Schema.DirectiveDefinition do
  @moduledoc false

  alias Absinthe.Blueprint

  @enforce_keys [:name]
  defstruct [
    :name,
    :module,
    :identifier,
    description: nil,
    directives: [],
    arguments: [],
    locations: [],
    errors: [],
    __reference__: nil
  ]

  @type t :: %__MODULE__{
          name: String.t(),
          description: nil,
          arguments: [Blueprint.Schema.InputValueDefinition.t()],
          locations: [String.t()],
          errors: [Absinthe.Phase.Error.t()]
        }
end
