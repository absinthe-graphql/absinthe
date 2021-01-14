defmodule Absinthe.Introspection.DirectiveLocation do
  @moduledoc false

  # https://spec.graphql.org/draft/#sec-Schema-Introspection

  @executable_directive_locations [
    :query,
    :mutation,
    :subscription,
    :field,
    :fragment_definition,
    :fragment_spread,
    :inline_fragment,
    :variable_definition
  ]
  @type_system_directive_locations [
    :schema,
    :scalar,
    :object,
    :field_definition,
    :argument_definition,
    :interface,
    :union,
    :enum,
    :enum_value,
    :input_object,
    :input_field_definition
  ]

  def values do
    @executable_directive_locations ++
      @type_system_directive_locations
  end
end
