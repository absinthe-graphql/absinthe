defmodule Absinthe.Schema.Rule.TypeNamesAreReservedTest do
  use Absinthe.Case, async: true
  use SupportSchemas

  alias Absinthe.Schema.Rule

  describe "rule" do

    it "is enforced" do
      assert_schema_error("prefix_schema",
                          [
                            %{rule: Rule.TypeNamesAreReserved, data: %{artifact: "type name", value: "__MyThing"}},
                            %{rule: Rule.TypeNamesAreReserved, data: %{artifact: "field name", value: "__mything"}},
                            %{rule: Rule.TypeNamesAreReserved, data: %{artifact: "argument name", value: "__myarg"}},
                            %{rule: Rule.TypeNamesAreReserved, data: %{artifact: "directive name", value: "__mydirective"}},
                            %{rule: Rule.TypeNamesAreReserved, data: %{artifact: "argument name", value: "__if"}}
                          ]
      )
    end

  end

end
