defmodule Absinthe.Phase.Schema.Compile do
  def run(blueprint, opts) do
    module_name = Module.concat(opts[:module], Compiled)

    types = build_types(blueprint)

    body = [
      types,
      quote do
        def __absinthe_type__(type) do
          Absinthe.Type.BuiltIns.__absinthe_type__(type)
        end
      end
    ]

    Module.create(module_name, body, Macro.Env.location(__ENV__))

    blueprint
  end

  def build_types(%{schema_definitions: [schema]}) do
    for type_def <- schema.types do
      type =
        %Absinthe.Type.Object{
          identifier: type_def.identifier,
          name: type_def.name,
          fields: build_fields(type_def, schema.module)
        }
        |> Macro.escape()

      quote do
        def __absinthe_type__(unquote(type_def.identifier)) do
          unquote(type)
        end

        def __absinthe_type__(unquote(type_def.name)) do
          unquote(type)
        end
      end
    end
  end

  def build_fields(type_def, module) do
    for field_def <- type_def.fields, into: %{} do
      # TODO: remove and make middleware work generally
      middleware_shim = {
        {__MODULE__, :shim},
        {module, type_def.identifier, field_def.identifier}
      }

      attrs =
        field_def
        |> Map.from_struct()
        |> Map.put(:middleware, [middleware_shim])

      field = struct(Absinthe.Type.Field, attrs)

      {field.identifier, field}
    end
  end

  def shim(res, {module, obj, field}) do
    middleware = apply(module, :__absinthe_middleware__, [obj, field])
    %{res | middleware: middleware}
  end
end
