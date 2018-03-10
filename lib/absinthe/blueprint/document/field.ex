defmodule Absinthe.Blueprint.Document.Field do
  @moduledoc false

  alias Absinthe.{Blueprint, Phase, Type}

  @enforce_keys [:name]
  defstruct [
    :name,
    alias: nil,
    selections: [],
    arguments: [],
    argument_data: %{},
    directives: [],
    # Added by phases
    flags: %{},
    errors: [],
    source_location: nil,
    type_conditions: [],
    schema_node: nil,
    complexity: nil
  ]

  @type t :: %__MODULE__{
          name: String.t(),
          selections: [Blueprint.Document.selection_t()],
          arguments: [Blueprint.Input.Argument.t()],
          directives: [Blueprint.Directive.t()],
          flags: Blueprint.flags_t(),
          errors: [Phase.Error.t()],
          source_location: nil | Blueprint.Document.SourceLocation.t(),
          type_conditions: [Blueprint.TypeReference.Name],
          schema_node: Type.t(),
          complexity: nil | non_neg_integer
        }
end
