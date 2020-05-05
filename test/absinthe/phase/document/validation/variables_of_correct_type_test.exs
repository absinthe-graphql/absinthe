defmodule Absinthe.Phase.Document.Validation.VariablesOfCorrectTypeTest do
  @phase Absinthe.Phase.Document.Arguments.VariableTypesMatch

  use Absinthe.ValidationPhaseCase, async: true, phase: @phase

  defp bad_argument(op_name, var_name, expected_type, inspected_type, line, verbose_errors) do
    bad_value(
      Blueprint.Input.Argument,
      error_message(op_name, var_name, expected_type, inspected_type, verbose_errors),
      line,
      name: var_name
    )
  end

  defp error_message(op_name, var_name, expected_type, inspected_type, []) do
    @phase.error_message(op_name, var_name, expected_type, inspected_type)
  end

  defp error_message(op_name, var_name, expected_type, inspected_type, verbose_errors) do
    @phase.error_message(op_name, var_name, expected_type, inspected_type) <>
      " " <> Enum.join(verbose_errors, " ")
  end

  test "types of variables match types of arguments" do
    assert_fails_validation(
      """
      query test($intArg: Int!) {
        complicatedArgs {
          stringArgField(stringArg: $intArg)
        }
      }
      """,
      [variables: %{"intArg" => 5}],
      [
        bad_argument("test", "intArg", "Int", "String", 3, [
          "(from line [%Absinthe.Blueprint.SourceLocation{column: 31, line: 3}])"
        ])
      ]
    )
  end

  test "types of variables match types of arguments even when the value is null" do
    assert_fails_validation(
      """
      query test($intArg: Int) {
        complicatedArgs {
          stringArgField(stringArg: $intArg)
        }
      }
      """,
      [variables: %{"intArg" => nil}],
      [
        bad_argument("test", "intArg", "Int", "String", 3, [
          "(from line [%Absinthe.Blueprint.SourceLocation{column: 31, line: 3}])"
        ])
      ]
    )
  end

  test "types of variables match types of arguments in named fragments" do
    assert_fails_validation(
      """
      query test($intArg: Int) {
        complicatedArgs {
          ...Fragment
        }
      }

      fragment Fragment on ComplicatedArgs {
        stringArgField(stringArg: $intArg)
      }
      """,
      [variables: %{"intArg" => 5}],
      [
        bad_argument("test", "intArg", "Int", "String", 8, [
          "(from line [%Absinthe.Blueprint.SourceLocation{column: 29, line: 8}])"
        ])
      ]
    )
  end
end
