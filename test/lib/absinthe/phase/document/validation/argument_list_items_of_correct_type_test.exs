defmodule Absinthe.Phase.Document.Validation.ArgumentListItemsOfCorrectTypeTest do
  use Absinthe.Case, async: true

  @rule Absinthe.Phase.Document.Validation.ArgumentListItemsOfCorrectType

  import Support.Harness.Validation
  alias Absinthe.{Blueprint, Phase}

  @spec bad_value(integer, String.t, any, nil | integer) :: Support.Harness.Validation.error_checker_t
  defp bad_value(index, type_name, value, line) do
    bad_value(index, type_name, value, line, [~s(In element ##{index + 1}: Expected type "#{type_name}", found #{value})])
  end

  @spec bad_value(integer, String.t, any, nil | integer, [String.t]) :: Support.Harness.Validation.error_checker_t
  defp bad_value(_index, _type_name, _value, line, errors) do
    fn
      pairs ->
        assert !Enum.empty?(pairs), "No errors were found"
        Enum.each(errors, fn
          message ->
            error_matched = Enum.any?(pairs, fn
              {%Blueprint.Input.List{flags: flags}, %Phase.Error{phase: @rule, message: ^message, locations: [%{line: ^line}]}} ->
                Enum.member?(flags, :invalid)
              _ ->
                false
            end)
            assert error_matched, "Could not find error:\n  ---\n  " <> message <> "\n  ---"
        end)
    end
  end

  describe "Invalid List value" do

    @tag :focus
    it "Incorrect item type" do
      assert_fails_rule(@rule,
        """
        {
          complicatedArgs {
            stringListArgField(stringListArg: ["one", 2])
          }
        }
        """,
        %{},
        bad_value(
          1, "String", "2", 3
        )
      )
    end

    it "Single value of incorrect type" do
      assert_fails_rule(@rule,
        """
        {
          complicatedArgs {
            stringListArgField(stringListArg: 1)
          }
        }
        """,
        %{},
        bad_value(
          0,
          "String",
          "1",
          3
        )
      )
    end

  end

end
