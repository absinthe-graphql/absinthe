defmodule Absinthe.Phase.Schema.InlineFunctions do
  @moduledoc false

  use Absinthe.Phase
  alias Absinthe.Blueprint
  alias Absinthe.Blueprint.Schema
  alias Absinthe.Type

  def run(blueprint, opts) do
    blueprint = Blueprint.prewalk(blueprint, &inline_functions(&1, blueprint.schema, opts))

    {:ok, blueprint}
  end

  def inline_functions(%Schema.SchemaDefinition{} = schema_def, schema, opts) do
    schema_def = %{
      schema_def
      | type_artifacts: Enum.map(schema_def.type_artifacts, &inline_functions(&1, schema, opts)),
        directive_artifacts:
          Enum.map(schema_def.directive_artifacts, &inline_functions(&1, schema, opts))
    }

    {:halt, schema_def}
  end

  def inline_functions(%type{identifier: _} = node, schema, opts) do
    type
    |> Schema.functions()
    # middleware gets handled specially
    |> Enum.reject(&(&1 in [:middleware]))
    |> Enum.reduce(node, &inline_function(&1, &2, opts))
    |> inline_middleware(schema, opts)
  end

  def inline_functions(node, _, _) do
    node
  end

  defp inline_function(attr, node, opts) do
    function = Type.function(node, attr)

    if Absinthe.Utils.escapable?(function) || opts[:inline_always] do
      %{node | attr => function}
    else
      node
    end
  end

  def inline_middleware(%type_name{} = type, schema, opts)
      when type_name in [Type.Object, Type.Union, Type.Interface] do
    Map.update!(type, :fields, fn fields ->
      fields =
        Enum.map(fields, fn {field_ident, field} ->
          {field_ident, inline_functions(field, schema, opts)}
        end)

      Map.new(fields, fn
        {field_ident, %{middleware: middleware} = field} ->
          expanded_middleware = Absinthe.Middleware.expand(schema, middleware, field, type)

          if Absinthe.Utils.escapable?(expanded_middleware) || opts[:inline_always] do
            {field_ident, %{field | middleware: expanded_middleware}}
          else
            middleware_shim = {
              {Absinthe.Middleware, :shim},
              {type.identifier, field.identifier, middleware}
            }

            {field_ident, %{field | middleware: [middleware_shim]}}
          end

        {field_ident, field} ->
          middleware = Absinthe.Middleware.expand(schema, field.middleware, field, type)

          {field_ident, %{field | middleware: middleware}}
      end)
    end)
  end

  def inline_middleware(type, _, _) do
    type
  end
end
