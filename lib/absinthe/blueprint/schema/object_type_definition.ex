defmodule Absinthe.Blueprint.Schema.ObjectTypeDefinition do
  @moduledoc false

  alias Absinthe.Blueprint

  @enforce_keys [:name, :identifier]
  defstruct [
    :name,
    :identifier,
    :module,
    description: nil,
    interfaces: [],
    fields: [],
    directives: [],
    is_type_of: nil,
    # Added by phases
    flags: %{},
    imports: [],
    errors: [],
    meta: %{},
    __reference__: nil
  ]

  @type t :: %__MODULE__{
          name: String.t(),
          identifier: atom,
          description: nil | String.t(),
          fields: [Blueprint.Schema.FieldDefinition.t()],
          interfaces: [String.t()],
          directives: [Blueprint.Directive.t()],
          # Added by phases
          flags: Blueprint.flags_t(),
          errors: [Absinthe.Phase.Error.t()]
        }

  def build(type_def, schema) do
    %Absinthe.Type.Object{
      identifier: type_def.identifier,
      name: type_def.name,
      description: type_def.description,
      fields: build_fields(type_def, schema.module)
    }
  end

  def build_fields(type_def, module) do
    for field_def <- type_def.fields, into: %{} do
      # TODO: remove and make middleware work generally
      middleware_shim = {
        {__MODULE__, :shim},
        {module, type_def.identifier, field_def.identifier}
      }

      field = %Absinthe.Type.Field{
        identifier: field_def.identifier,
        middleware: [middleware_shim],
        deprecation: field_def.deprecation,
        description: field_def.description,
        name: field_def.name,
        type: field_def.type,
        args: build_args(field_def)
      }

      {field.identifier, field}
    end
  end

  defp build_args(field_def) do
    Map.new(field_def.arguments, fn arg_def ->
      arg = %Absinthe.Type.Argument{
        identifier: arg_def.identifier,
        name: arg_def.name,
        type: arg_def.type
      }

      {arg_def.identifier, arg}
    end)
  end

  def shim(res, {module, obj, field} = k) do
    middleware =
      apply(module, :__absinthe_function__, [
        Absinthe.Type.Field,
        {obj, field},
        :middleware
      ])

    %{res | middleware: middleware}
  end
end
