defmodule Absinthe.Phase.Schema.Build do
  @moduledoc false

  def run(blueprint, _opts) do
    %{schema_definitions: [schema]} = blueprint

    types = build_types(blueprint)
    directives = build_directives(blueprint)

    schema = %{schema | type_artifacts: types, directive_artifacts: directives}

    blueprint = %{blueprint | schema_definitions: [schema]}

    {:ok, blueprint}
  end

  def inline_middleware(%Absinthe.Type.Object{} = type, schema) do
    Map.update!(type, :fields, fn fields ->
      Map.new(fields, fn
        {field_ident, %{middleware: {:ref, module, identifier}} = field} ->
          middleware = Absinthe.Type.function(field, :middleware)
          middleware = Absinthe.Middleware.expand(schema, middleware, field, type)

          if Absinthe.Utils.escapable?(middleware) do
            {field_ident, %{field | middleware: middleware}}
          else
            middleware_shim = {
              {Absinthe.Middleware, :shim},
              {:ref, module, identifier}
            }

            {field_ident, %{field | middleware: [middleware_shim]}}
          end

        {field_ident, field} ->
          middleware = Absinthe.Middleware.expand(schema, field.middleware, field, type)

          {field_ident, %{field | middleware: middleware}}
      end)
    end)
  end

  def inline_middleware(type, _) do
    type
  end

  def build_types(%{schema_definitions: [schema]} = bp) do
    for %module{} = type_def <- schema.type_definitions do
      type = module.build(type_def, schema)
      type = inline_middleware(type, bp.schema)

      %{
        type
        | __reference__: type_def.__reference__,
          __private__: type_def.__private__
      }
    end
  end

  def build_directives(%{schema_definitions: [schema]}) do
    for %module{} = type_def <- schema.directive_definitions do
      type = module.build(type_def, schema)

      %{
        type
        | definition: type_def.module,
          __reference__: type_def.__reference__,
          __private__: type_def.__private__
      }
    end
  end
end
