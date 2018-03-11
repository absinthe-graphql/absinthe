defmodule Absinthe.Blueprint.Schema.EnumTypeDefinition do
  @moduledoc false

  alias Absinthe.Blueprint

  @enforce_keys [:name]
  defstruct [
    :name,
    :identifier,
    :description,
    values: [],
    directives: [],
    # Added by phases,
    flags: %{},
    errors: []
  ]

  @type t :: %__MODULE__{
          name: String.t(),
          values: [String.t()],
          directives: [Blueprint.Directive.t()],
          # Added by phases
          flags: Blueprint.flags_t(),
          errors: [Absinthe.Phase.Error.t()]
        }
  def build(type_def, _schema) do
    %Absinthe.Type.Enum{
      identifier: type_def.identifier,
      name: type_def.name
    }
  end
end
