defmodule Absinthe.Phase.Document.Validation.UniqueArgumentNamesTest do
  use Absinthe.Case, async: true

  @rule Absinthe.Phase.Document.Validation.UniqueArgumentNames

  use Support.Harness.Validation
  alias Absinthe.{Blueprint}

  defp duplicate(name, line, values) do
    List.wrap(values)
    |> Enum.map(fn
      value ->
        bad_value(Blueprint.Input.Argument, @rule.error_message, line, literal_value_check(name, value))
    end)
  end

  defp literal_value_check(name, value) do
    fn
      %{name: ^name, input_value: %{literal: %{value: ^value}}} ->
        true
      _ ->
        false
    end
  end

  describe "Validate: Unique argument names" do

    it "no arguments on field" do
      assert_passes_rule(@rule,
        """
        {
          field
        }
        """,
        []
      )
    end

    it "no arguments on directive" do
      assert_passes_rule(@rule,
        """
        {
          field @directive
        }
        """,
        []
      )
    end

    it "argument on field" do
      assert_passes_rule(@rule,
        """
        {
          field(arg: "value")
        }
        """,
        []
      )
    end

    it "argument on directive" do
      assert_passes_rule(@rule,
        """
        {
          field @directive(arg: "value")
        }
        """,
        []
      )
    end

    it "same argument on two fields" do
      assert_passes_rule(@rule,
        """
        {
          one: field(arg: "value")
          two: field(arg: "value")
        }
        """,
        []
      )
    end

    it "same argument on field and directive" do
      assert_passes_rule(@rule,
        """
        {
          field(arg: "value") @directive(arg: "value")
        }
        """,
        []
      )
    end

    it "same argument on two directives" do
      assert_passes_rule(@rule,
      """
        {
          field @directive1(arg: "value") @directive2(arg: "value")
        }
        """,
        []
      )
    end

    it "multiple field arguments" do
      assert_passes_rule(@rule,
        """
        {
          field(arg1: "value", arg2: "value", arg3: "value")
        }
        """,
        []
      )
    end

    it "multiple directive arguments" do
      assert_passes_rule(@rule,
        """
        {
          field @directive(arg1: "value", arg2: "value", arg3: "value")
        }
        """,
        []
      )
    end

    it "duplicate field arguments" do
      assert_fails_rule(@rule,
        """
        {
          field(arg1: "value1", arg1: "value2")
        }
        """,
        [],
        duplicate("arg1", 2, ~w(value1 value2))
      )
    end

    it "many duplicate field arguments" do
      assert_fails_rule(@rule,
        """
        {
          field(arg1: "value1", arg1: "value2", arg1: "value3")
        }
        """,
        [],
        duplicate("arg1", 2, ~w(value1 value2 value3))
      )
    end

    it "duplicate directive arguments" do
      assert_fails_rule(@rule,
        """
        {
          field @directive(arg1: "value1", arg1: "value2")
        }
        """,
        [],
        duplicate("arg1", 2, ~w(value1 value2))
      )
    end

    it "many duplicate directive arguments" do
      assert_fails_rule(@rule,
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
