defmodule Absinthe.Schema.Rule.DirectivesMustBeValidTest do
  use Absinthe.Case, async: true

  alias Absinthe.Phase.Schema.Validation.DirectivesMustBeValid

  describe "rule" do
    test "is enforced" do
      assert_schema_error("bad_directives_schema", [
        %{phase: DirectivesMustBeValid, extra: %{}},
        %{phase: DirectivesMustBeValid, extra: %{location: :unknown}}
      ])
    end
  end
end
