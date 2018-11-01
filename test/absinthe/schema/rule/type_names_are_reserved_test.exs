defmodule Absinthe.Schema.Rule.TypeNamesAreReservedTest do
  use Absinthe.Case, async: true

  alias Absinthe.Phase.Schema.Validation.TypeNamesAreReserved

  describe "rule" do
    test "is enforced" do
      assert_schema_error("prefix_schema", [
        %{phase: TypeNamesAreReserved, extra: %{artifact: "type name", value: "__MyThing"}},
        %{phase: TypeNamesAreReserved, extra: %{artifact: "field name", value: "__mything"}},
        %{phase: TypeNamesAreReserved, extra: %{artifact: "argument name", value: "__myarg"}},
        %{
          phase: TypeNamesAreReserved,
          extra: %{artifact: "directive name", value: "__mydirective"}
        },
        %{phase: TypeNamesAreReserved, extra: %{artifact: "argument name", value: "__if"}}
      ])
    end
  end
end
