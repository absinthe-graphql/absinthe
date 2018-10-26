defmodule Absinthe.Schema.Rule.QueryTypeMustBeObjectTest do
  use Absinthe.Case, async: true

  alias Absinthe.Schema.Rule

  describe "rule" do
    test "is enforced" do
      assert_schema_error("empty_schema", [
        %{rule: Rule.QueryTypeMustBeObject, data: %{}}
      ])
    end
  end
end
