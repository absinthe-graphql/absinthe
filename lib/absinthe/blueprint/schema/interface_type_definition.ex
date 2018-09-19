defmodule Absinthe.Blueprint.Schema.InterfaceTypeDefinition do
  @moduledoc false

  alias Absinthe.Blueprint

  @enforce_keys [:name]
  defstruct [
    :identifier,
    :name,
    :module,
    description: nil,
    fields: [],
    directives: [],
    source_location: nil,
    # Added by phases
    flags: %{},
    errors: [],
    resolve_type: nil,
    imports: [],
    __reference__: nil,
    __private__: []
  ]

  @type t :: %__MODULE__{
          name: String.t(),
          description: nil | String.t(),
          fields: [Blueprint.Schema.FieldDefinition.t()],
          directives: [Blueprint.Directive.t()],
          source_location: nil | Blueprint.SourceLocation.t(),
          # Added by phases
          flags: Blueprint.flags_t(),
          errors: [Absinthe.Phase.Error.t()]
        }

  def build(type_def, _schema) do
    %Absinthe.Type.Interface{
      name: type_def.name,
      description: type_def.description,
      fields: build_fields(type_def),
      identifier: type_def.identifier,
      resolve_type: type_def.resolve_type,
      definition: type_def.module
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
