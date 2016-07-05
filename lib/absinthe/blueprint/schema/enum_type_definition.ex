defmodule Absinthe.Blueprint.Schema.EnumTypeDefinition do

  alias Absinthe.Blueprint

  defstruct [
    :name,
    values: [],
    directives: [],
    errors: [],
  ]

  @type t :: %__MODULE__{
    name: String.t,
    values: [String.t],
    directives: [Blueprint.Document.Directive.t],
    errors: [Absinthe.Phase.Error.t],
  }

end
