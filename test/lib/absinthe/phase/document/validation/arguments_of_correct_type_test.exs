defmodule Absinthe.Phase.Document.Validation.ArgumentsOfCorrectTypeTest do
  use Absinthe.Case, async: true

  @rule Absinthe.Phase.Document.Validation.ArgumentsOfCorrectType

  import Support.Harness.Validation
  alias Absinthe.{Blueprint, Phase}

  @spec bad_value_matcher(String.t, String.t, any, nil | integer) :: Support.Harness.Validation.error_matcher_t
  defp bad_value_matcher(arg_name, type_name, value, line) do
    message = ~s(Expected type "#{type_name}", found #{value})
    fn
      {%Blueprint.Input.Argument{name: ^arg_name, flags: flags}, %Phase.Error{phase: @rule, message: ^message, locations: [%{line: ^line}]}}
      ->
        Enum.member?(flags, :invalid)
      _ ->
        false
    end
  end

  describe "Validate: Argument values of correct type" do

    describe "Valid values" do

      it "Good int value" do
        assert_passes_rule(@rule, """
          {
            complicatedArgs {
              intArgField(intArg: 2)
            }
          }
        """, %{})
      end

    end

    describe "Invalid values" do

      describe "Invalid String values" do

        it "Int into String" do
          assert_fails_rule(@rule, """
            {
              complicatedArgs {
                stringArgField(stringArg: 1)
              }
            }
            """, %{}, bad_value_matcher("stringArg", "String", "1", 3))
        end

      end

    end

  end

end
