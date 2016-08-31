defmodule Absinthe.Phase.Document.Validation.UniqueInputFieldNamesTest do
  use Absinthe.Case, async: true

  @rule Absinthe.Phase.Document.Validation.UniqueInputFieldNames

  use Support.Harness.Validation
  alias Absinthe.{Blueprint}

  @message "Duplicate input field name."

  defp duplicate(name, line, values) do
    List.wrap(values)
    |> Enum.map(fn
      value ->
        bad_value(Blueprint.Input.Field, @message, line, literal_value_check(name, value))
    end)
  end

  defp literal_value_check(name, value) do
    fn
      %{name: ^name, value: %{value: ^value}} ->
        true
      _ ->
        false
    end
  end

  describe "Validate: Unique input field names" do

    it "input object with fields" do
      assert_passes_rule(@rule,
        """
        {
          field(arg: { f: true })
        }
        """,
        %{}
      )
    end

    it "same input object within two args" do
      assert_passes_rule(@rule,
        """
        {
          field(arg1: { f: true }, arg2: { f: true })
        }
        """,
        %{}
      )
    end

    it "multiple input object fields" do
      assert_passes_rule(@rule,
        """
        {
          field(arg: { f1: "value", f2: "value", f3: "value" })
        }
        """,
        %{}
      )
    end

    it "allows for nested input objects with similar fields" do
      assert_passes_rule(@rule,
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
        %{}
      )
    end

    it "duplicate input object fields" do
      assert_fails_rule(@rule,
        """
        {
          field(arg: { f1: "value1", f1: "value2" })
        }
        """,
        %{},
        duplicate("f1", 2, ~w(value1 value2))
      )
    end

    it "many duplicate input object fields" do
      assert_fails_rule(@rule,
        """
        {
          field(arg: { f1: "value1", f1: "value2", f1: "value3" })
        }
        """,
        %{},
        duplicate("f1", 2, ~w(value1 value2 value3))
      )
    end

  end

end
