defmodule Absinthe.Schema.Rule.InputOuputTypesCorrectlyPlacedTest do
  use Absinthe.Case, async: true

  describe "rule" do
    test "is enforced with output types on arguments" do
      assert_schema_error("invalid_output_types", [
        %{
          data: %{
            field: :blah,
            parent: Absinthe.Type.Object,
            struct: Absinthe.Type.InputObject,
            type: :input
          },
          location: %{
            file: "/Users/ben/src/absinthe/test/support/fixtures/dynamic/invalid_output_types.exs",
            line: 10
          },
          rule: Absinthe.Schema.Rule.InputOuputTypesCorrectlyPlaced
        },
        %{
          data: %{argument: :invalid_arg, struct: Absinthe.Type.Object, type: :user},
          location: %{
            file: "/Users/ben/src/absinthe/test/support/fixtures/dynamic/invalid_output_types.exs",
            line: 4
          },
          rule: Absinthe.Schema.Rule.InputOuputTypesCorrectlyPlaced
        }
      ])
    end

    test "is enforced with input types on arguments" do
      assert_schema_error("invalid_input_types", [
        %{
          data: %{
            field: :blah,
            parent: Absinthe.Type.InputObject,
            struct: Absinthe.Type.Object,
            type: :user
          },
          location: %{
            file: "/Users/ben/src/absinthe/test/support/fixtures/dynamic/invalid_input_types.exs",
            line: 7
          },
          rule: Absinthe.Schema.Rule.InputOuputTypesCorrectlyPlaced
        }
      ])
    end
  end
end
