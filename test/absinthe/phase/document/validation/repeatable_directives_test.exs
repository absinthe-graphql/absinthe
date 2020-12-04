defmodule Absinthe.Phase.Document.Validation.RepeatableDirectivesTest do
  @phase Absinthe.Phase.Document.Validation.RepeatableDirectives

  use Absinthe.ValidationPhaseCase,
    phase: @phase,
    async: true

  alias Absinthe.Blueprint

  defp duplicate(name, line) do
    bad_value(
      Blueprint.Directive,
      "Directive `#{name}' cannot be applied repeatedly.",
      line,
      name: name
    )
  end

  test "with disallowed repeated directives" do
    assert_fails_validation(
      """
      query Foo {
        skippedField @skip(if: true) @skip(if: true)
      }
      """,
      [],
      duplicate("skip", 2)
    )
  end

  test "with allowed repeated directives" do
    assert_passes_validation(
      """
      query Foo {
        skippedField @onField @onField
      }

      mutation Bar @onMutation {
        someField
      }
      """,
      []
    )
  end
end
