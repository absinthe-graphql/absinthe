defmodule Absinthe.Phase.Schema.InlineFunctions do
  @moduledoc false

  use Absinthe.Phase
  alias Absinthe.Blueprint
  alias Absinthe.Blueprint.Schema
  alias Absinthe.Type

  def run(blueprint, _opts) do
    blueprint = Blueprint.prewalk(blueprint, &inline_functions(&1, blueprint.schema))

    {:ok, blueprint}
  end

  def inline_functions(%Schema.SchemaDefinition{} = schema_def, schema) do
    schema_def = %{
      schema_def
      | type_artifacts: Enum.map(schema_def.type_artifacts, &inline_functions(&1, schema)),
        directive_artifacts:
          Enum.map(schema_def.directive_artifacts, &inline_functions(&1, schema))
    }

    {:halt, schema_def}
  end

  def inline_functions(%type{identifier: _} = node, schema) do
    type
    |> Schema.functions()
    # middleware gets handled specially
    |> Enum.reject(&(&1 in [:middleware]))
    |> Enum.reduce(node, &inline_function/2)
    |> inline_middleware(schema)
  end

  def inline_functions(node, _) do
    node
  end

  defp inline_function(attr, node) do
    function = Type.function(node, attr)

    if Absinthe.Utils.escapable?(function) do
      %{node | attr => function}
    else
      node
    end
  end

  def inline_middleware(%type_name{} = type, schema)
      when type_name in [Type.Object, Type.Union, Type.Interface] do
    Map.update!(type, :fields, fn fields ->
      fields =
        Enum.map(fields, fn {field_ident, field} ->
          {field_ident, inline_functions(field, schema)}
        end)

      Map.new(fields, fn
        {field_ident, %{middleware: middleware} = field} ->
          expanded_middleware = Absinthe.Middleware.expand(schema, middleware, field, type)

          if Absinthe.Utils.escapable?(expanded_middleware) do
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

  def inline_middleware(type, _) do
    type
  end
end
