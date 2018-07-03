defmodule Absinthe.Phase.Document.Validation.UniqueArgumentNamesTest do
  @phase Absinthe.Phase.Document.Validation.UniqueArgumentNames

  use Absinthe.ValidationPhaseCase,
    phase: @phase,
    async: true

  alias Absinthe.{Blueprint}

  defp duplicate(name, line, values) do
    List.wrap(values)
    |> Enum.map(fn value ->
      bad_value(
        Blueprint.Input.Argument,
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

  describe "Validate: Unique argument names" do
    test "no arguments on field" do
      assert_passes_validation(
        """
        {
          field
        }
        """,
        []
      )
    end

    test "no arguments on directive" do
      assert_passes_validation(
        """
        {
          field @directive
        }
        """,
        []
      )
    end

    test "argument on field" do
      assert_passes_validation(
        """
        {
          field(arg: "value")
        }
        """,
        []
      )
    end

    test "argument on directive" do
      assert_passes_validation(
        """
        {
          field @directive(arg: "value")
        }
        """,
        []
      )
    end

    test "same argument on two fields" do
      assert_passes_validation(
        """
        {
          one: field(arg: "value")
          two: field(arg: "value")
        }
        """,
        []
      )
    end

    test "same argument on field and directive" do
      assert_passes_validation(
        """
        {
          field(arg: "value") @directive(arg: "value")
        }
        """,
        []
      )
    end

    test "same argument on two directives" do
      assert_passes_validation(
        """
        {
          field @directive1(arg: "value") @directive2(arg: "value")
        }
        """,
        []
      )
    end

    test "multiple field arguments" do
      assert_passes_validation(
        """
        {
          field(arg1: "value", arg2: "value", arg3: "value")
        }
        """,
        []
      )
    end

    test "multiple directive arguments" do
      assert_passes_validation(
        """
        {
          field @directive(arg1: "value", arg2: "value", arg3: "value")
        }
        """,
        []
      )
    end

    test "duplicate field arguments" do
      assert_fails_validation(
        """
        {
          field(arg1: "value1", arg1: "value2")
        }
        """,
        [],
        duplicate("arg1", 2, ~w(value1 value2))
      )
    end

    test "many duplicate field arguments" do
      assert_fails_validation(
        """
        {
          field(arg1: "value1", arg1: "value2", arg1: "value3")
        }
        """,
        [],
        duplicate("arg1", 2, ~w(value1 value2 value3))
      )
    end

    test "duplicate directive arguments" do
      assert_fails_validation(
        """
        {
          field @directive(arg1: "value1", arg1: "value2")
        }
        """,
        [],
        duplicate("arg1", 2, ~w(value1 value2))
      )
    end

    test "many duplicate directive arguments" do
      assert_fails_validation(
        """
        {
          field @directive(arg1: "value1", arg1: "value2", arg1: "value3")
        }
        """,
        [],
        duplicate("arg1", 2, ~w(value1 value2 value3))
      )
    end
  end
end
