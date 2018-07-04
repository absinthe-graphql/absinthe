defmodule Absinthe.Phase.Document.Validation.UniqueInputFieldNamesTest do
  @phase Absinthe.Phase.Document.Validation.UniqueInputFieldNames

  use Absinthe.ValidationPhaseCase,
    phase: @phase,
    async: true

  alias Absinthe.{Blueprint}

  defp duplicate(name, line, values) do
    List.wrap(values)
    |> Enum.map(fn value ->
      bad_value(
        Blueprint.Input.Field,
        @phase.error_message,
        line,
        literal_value_check(name, value)
      )
    end)
  end

  defp literal_value_check(name, value) do
    fn
      %{name: ^name, input_value: %{normalized: %{value: ^value}}} ->
        true

      _ ->
        false
    end
  end

  describe "Validate: Unique input field names" do
    test "input object with fields" do
      assert_passes_validation(
        """
        {
          field(arg: { f: true })
        }
        """,
        []
      )
    end

    test "same input object within two args" do
      assert_passes_validation(
        """
        {
          field(arg1: { f: true }, arg2: { f: true })
        }
        """,
        []
      )
    end

    test "multiple input object fields" do
      assert_passes_validation(
        """
        {
          field(arg: { f1: "value", f2: "value", f3: "value" })
        }
        """,
        []
      )
    end

    test "allows for nested input objects with similar fields" do
      assert_passes_validation(
        """
        {
          field(arg: {
            deep: {
              deep: {
                id: 1
              }
              id: 1
            }
            id: 1
          })
        }
        """,
        []
      )
    end

    test "duplicate input object fields" do
      assert_fails_validation(
        """
        {
          field(arg: { f1: "value1", f1: "value2" })
        }
        """,
        [],
        duplicate("f1", 2, ~w(value1 value2))
      )
    end

    test "many duplicate input object fields" do
      assert_fails_validation(
        """
        {
          field(arg: { f1: "value1", f1: "value2", f1: "value3" })
        }
        """,
        [],
        duplicate("f1", 2, ~w(value1 value2 value3))
      )
    end
  end
end
