defmodule Absinthe.Schema.Rule.NoInterfacecyclesTest do
  use Absinthe.Case, async: true

  describe "rule" do
    test "is enforced" do
      assert_schema_error("interface_cycle_schema", [
        %{
          extra: :named,
          locations: [
            %{
              file: "test/support/fixtures/dynamic/interface_cycle_schema.exs",
              line: 24
            }
          ],
          message:
            "Interface Cycle Error\n\nInterface `named' forms a cycle via: ([:named, :node, :named])",
          path: [],
          phase: Absinthe.Phase.Schema.Validation.NoInterfaceCyles
        },
        %{
          extra: :node,
          locations: [
            %{
              file: "test/support/fixtures/dynamic/interface_cycle_schema.exs",
              line: 24
            }
          ],
          message:
            "Interface Cycle Error\n\nInterface `node' forms a cycle via: ([:node, :named, :node])",
          path: [],
          phase: Absinthe.Phase.Schema.Validation.NoInterfaceCyles
        }
      ])
    end
  end
end
