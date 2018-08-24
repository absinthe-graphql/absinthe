defmodule Absinthe.Blueprint.Schema.ObjectTypeDefinition do
  @moduledoc false

  alias Absinthe.{Blueprint, Type}

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
    __reference__: nil,
    __private__: []
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
          errors: [Absinthe.Phase.Error.t()],
          __private__: Keyword.t()
        }

  def build(type_def, schema) do
    %Type.Object{
      identifier: type_def.identifier,
      name: type_def.name,
      description: type_def.description,
      fields: build_fields(type_def, schema.module),
      interfaces: type_def.interfaces
    }
  end

  def build_fields(type_def, module) do
    for field_def <- type_def.fields, into: %{} do
      # TODO: remove and make middleware work generally
      middleware_shim = {
        {__MODULE__, :shim},
        {module, type_def.identifier, field_def.identifier}
      }

      field = %Type.Field{
        identifier: field_def.identifier,
        middleware: [middleware_shim],
        deprecation: Type.Deprecation.build(field_def.deprecation),
        description: field_def.description,
        complexity: {type_def.identifier, field_def.identifier},
        config: {type_def.identifier, field_def.identifier},
        name: field_def.name,
        type: field_def.type,
        args: build_args(field_def),
        definition: module,
        __reference__: field_def.__reference__,
        __private__: field_def.__private__
      }

      {field.identifier, field}
    end
  end

  def build_args(field_def) do
    Map.new(field_def.arguments, fn arg_def ->
      arg = %Type.Argument{
        identifier: arg_def.identifier,
        name: arg_def.name,
        type: arg_def.type,
        default_value: arg_def.default_value,
        deprecation: Type.Deprecation.build(arg_def.deprecation)
      }

      {arg_def.identifier, arg}
    end)
  end

  def shim(res, {module, obj, field}) do
    middleware =
      apply(module, :__absinthe_function__, [
        Type.Field,
        {obj, field},
        :middleware
      ])

    %{res | middleware: middleware}
  end
end
