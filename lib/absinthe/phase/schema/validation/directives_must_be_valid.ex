defmodule Absinthe.Phase.Schema.Validation.DirectivesMustBeValid do
  @moduledoc false

  use Absinthe.Phase
  alias Absinthe.Blueprint

  @doc """
  Run the validation.
  """
  def run(bp, _) do
    bp = Blueprint.prewalk(bp, &handle_schemas/1)
    {:ok, bp}
  end

  defp handle_schemas(%Blueprint.Schema.SchemaDefinition{} = schema) do
    directive_definitions = Enum.map(schema.directive_definitions, &validate_directive(&1))

    {:halt, %{schema | directive_definitions: directive_definitions}}
  end

  defp handle_schemas(obj) do
    obj
  end

  defp validate_directive(%Blueprint.Schema.DirectiveDefinition{locations: []} = directive) do
    directive |> put_error(error_locations_absent(directive))
  end

  defp validate_directive(%Blueprint.Schema.DirectiveDefinition{locations: locations} = directive) do
    directive =
      Enum.reduce(locations, directive, fn location, directive ->
        validate_location(directive, location)
      end)

    directive
  end

  defp validate_directive(directive) do
    directive
  end

  @directive_locations [
    :argument_definition,
    :enum_value,
    :enum,
    :field_definition,
    :field,
    :fragment_definition,
    :fragment_spread,
    :inline_fragment,
    :input_field_definition,
    :input_object,
    :interface,
    :mutation,
    :object,
    :query,
    :scalar,
    :schema,
    :subscription,
    :union
  ]

  defp validate_location(directive, location) when location in @directive_locations do
    directive
  end

  defp validate_location(directive, location) do
    directive |> put_error(error_unknown_directive_location(directive, location))
  end

  defp error_unknown_directive_location(directive, location) do
    %Absinthe.Phase.Error{
      message: explanation(directive, location),
      locations: [directive.__reference__.location],
      phase: __MODULE__,
      extra: %{
        location: location
      }
    }
  end

  defp error_locations_absent(directive) do
    %Absinthe.Phase.Error{
      message: explanation(directive),
      locations: [directive.__reference__.location],
      phase: __MODULE__
    }
  end

  defp explanation(directive, location) do
    """
    Directive "#{directive.name}" must use a valid DirectiveLocation

    Found: #{inspect(location)}

    Expected one/multiple of: #{inspect(@directive_locations)}

    Reference: http://spec.graphql.org/June2018/#sec-Type-System.Directives
    """
  end

  defp explanation(directive) do
    """
    Directive "#{directive.name}" must set DirectiveLocations

    Expected one/multiple of: #{inspect(@directive_locations)}

    Reference: http://spec.graphql.org/June2018/#sec-Type-System.Directives
    """
  end
end
