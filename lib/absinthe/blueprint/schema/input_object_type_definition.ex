defmodule Absinthe.Blueprint.Schema.InputObjectTypeDefinition do
  @moduledoc false

  alias Absinthe.Blueprint

  @enforce_keys [:name]
  defstruct [
    :identifier,
    :name,
    :module,
    description: nil,
    interfaces: [],
    fields: [],
    directives: [],
    # Added by phases,
    flags: %{},
    errors: [],
    __reference__: nil
  ]

  @type t :: %__MODULE__{
          name: String.t(),
          description: nil | String.t(),
          fields: [Blueprint.Schema.InputValueDefinition.t()],
          directives: [Blueprint.Directive.t()],
          # Added by phases
          flags: Blueprint.flags_t(),
          errors: [Absinthe.Phase.Error.t()]
        }

  def build(type_def, _schema) do
    %Absinthe.Type.InputObject{
      identifier: type_def.identifier,
      name: type_def.name,
      fields: build_fields(type_def)
    }
  end

  def build_fields(type_def) do
    for field_def <- type_def.fields, into: %{} do
      attrs =
        field_def
        |> Map.from_struct()

      field = struct(Absinthe.Type.Field, attrs)

      {field.identifier, field}
    end
  end
end
