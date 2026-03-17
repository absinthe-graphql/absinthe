defmodule Elixir.Absinthe.Integration.Execution.Introspection.DirectivesTest do
  use Absinthe.Case, async: true

  @query """
  query {
    __schema {
      directives {
        name
        args { name type { kind ofType { name kind } } }
        locations
        isRepeatable
        onField
        onFragment
        onOperation
      }
    }
  }
  """

  test "scenario #1" do
    # Note: @defer and @stream directives are opt-in and not included in core schemas
    # They need to be explicitly imported via: import_directives Absinthe.Type.BuiltIns.IncrementalDirectives
    {:ok, result} = Absinthe.run(@query, Absinthe.Fixtures.ContactSchema, [])

    directives = get_in(result, [:data, "__schema", "directives"])
    directive_names = Enum.map(directives, & &1["name"])

    # Core directives should always be present
    assert "deprecated" in directive_names
    assert "include" in directive_names
    assert "skip" in directive_names
    assert "specifiedBy" in directive_names

    # @defer and @stream are opt-in, not in core schema
    refute "defer" in directive_names
    refute "stream" in directive_names
  end
end
