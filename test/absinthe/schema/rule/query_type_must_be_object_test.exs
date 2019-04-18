defmodule Absinthe.Schema.Rule.QueryTypeMustBeObjectTest do
  use Absinthe.Case, async: true

  describe "rule" do
    test "is enforced" do
      assert_schema_error("empty_schema", [
        %{
          phase: Absinthe.Phase.Schema.Validation.QueryTypeMustBeObject,
          extra: %{},
          locations: [
            %{
              file: "test/support/fixtures/dynamic/empty_schema.exs",
              line: 0
            }
          ]
        }
      ])
    end
  end
end
