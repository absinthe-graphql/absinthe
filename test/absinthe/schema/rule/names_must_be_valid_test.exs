defmodule Absinthe.Schema.Rule.NamesMustBeValidTest do
  use Absinthe.Case, async: true

  alias Absinthe.Phase.Schema.Validation.NamesMustBeValid

  describe "rule" do
    test "is enforced" do
      assert_schema_error("bad_names_schema", [
        %{phase: NamesMustBeValid, extra: %{artifact: "field name", value: "bad field name"}},
        %{phase: NamesMustBeValid, extra: %{artifact: "argument name", value: "bad arg name"}},
        %{
          phase: NamesMustBeValid,
          extra: %{artifact: "directive name", value: "bad directive name"}
        },
        %{phase: NamesMustBeValid, extra: %{artifact: "scalar name", value: "bad?scalar#name"}},
        %{phase: NamesMustBeValid, extra: %{artifact: "object name", value: "bad object name"}},
        %{
          phase: NamesMustBeValid,
          extra: %{artifact: "input object name", value: "bad input name"}
        }
      ])
    end
  end
end
