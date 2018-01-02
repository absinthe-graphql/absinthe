defmodule Absinthe.Schema.Rule.QueryTypeMustBeObjectTest do
  use Absinthe.Case, async: true
  use SupportSchemas

  alias Absinthe.Schema.Rule

  context "rule" do

    test "is enforced" do
      assert_schema_error("empty_schema",
                          [
                            %{rule: Rule.QueryTypeMustBeObject, data: %{}},
                          ]
      )
    end

  end

end
