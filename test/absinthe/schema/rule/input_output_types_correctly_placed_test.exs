defmodule Absinthe.Schema.Rule.InputOutputTypesCorrectlyPlacedTest do
  use Absinthe.Case, async: true

  describe "macro schema" do
    test "is enforced with output types on arguments" do
      assert_schema_error("invalid_output_types", [
        %{
          extra: %{
            field: :blah,
            parent: Absinthe.Blueprint.Schema.ObjectTypeDefinition,
            struct: Absinthe.Blueprint.Schema.InputObjectTypeDefinition,
            type: :input
          },
          locations: [
            %{
              file: "test/support/fixtures/dynamic/invalid_output_types.exs",
              line: 11
            }
          ],
          phase: Absinthe.Phase.Schema.Validation.InputOutputTypesCorrectlyPlaced
        },
        %{
          extra: %{
            argument: :invalid_arg,
            struct: Absinthe.Blueprint.Schema.ObjectTypeDefinition,
            type: :user
          },
          locations: [
            %{
              file: "test/support/fixtures/dynamic/invalid_output_types.exs",
              line: 16
            }
          ],
          phase: Absinthe.Phase.Schema.Validation.InputOutputTypesCorrectlyPlaced
        }
      ])
    end

    test "is enforced with input types on arguments" do
      assert_schema_error("invalid_input_types", [
        %{
          extra: %{
            field: :blah,
            parent: Absinthe.Blueprint.Schema.InputObjectTypeDefinition,
            struct: Absinthe.Blueprint.Schema.ObjectTypeDefinition,
            type: :user
          },
          locations: [
            %{
              file: "test/support/fixtures/dynamic/invalid_input_types.exs",
              line: 8
            }
          ],
          phase: Absinthe.Phase.Schema.Validation.InputOutputTypesCorrectlyPlaced
        }
      ])
    end
  end

  describe "sdl schema" do
    test "is enforced with output types on arguments" do
      assert_schema_error("invalid_output_types_sdl", [
        %{
          extra: %{
            field: :blah,
            parent: Absinthe.Blueprint.Schema.ObjectTypeDefinition,
            struct: Absinthe.Blueprint.Schema.InputObjectTypeDefinition,
            type: :input
          },
          locations: [
            %{
              file: "test/support/fixtures/dynamic/invalid_output_types_sdl.exs",
              line: 4
            }
          ],
          phase: Absinthe.Phase.Schema.Validation.InputOutputTypesCorrectlyPlaced
        },
        %{
          extra: %{
            argument: :invalid_arg,
            struct: Absinthe.Blueprint.Schema.ObjectTypeDefinition,
            type: :user
          },
          locations: [
            %{
              file: "test/support/fixtures/dynamic/invalid_output_types_sdl.exs",
              line: 4
            }
          ],
          phase: Absinthe.Phase.Schema.Validation.InputOutputTypesCorrectlyPlaced
        }
      ])
    end

    test "is enforced with input types on arguments" do
      assert_schema_error("invalid_input_types_sdl", [
        %{
          extra: %{
            argument: :blah,
            struct: Absinthe.Blueprint.Schema.ObjectTypeDefinition,
            type: :user
          },
          locations: [
            %{
              file: "test/support/fixtures/dynamic/invalid_input_types_sdl.exs",
              line: 4
            }
          ],
          phase: Absinthe.Phase.Schema.Validation.InputOutputTypesCorrectlyPlaced
        },
        %{
          extra: %{
            field: :blah,
            parent: Absinthe.Blueprint.Schema.InputObjectTypeDefinition,
            struct: Absinthe.Blueprint.Schema.ObjectTypeDefinition,
            type: :user
          },
          locations: [
            %{
              file: "test/support/fixtures/dynamic/invalid_input_types_sdl.exs",
              line: 4
            }
          ],
          phase: Absinthe.Phase.Schema.Validation.InputOutputTypesCorrectlyPlaced
        }
      ])
    end
  end
end
