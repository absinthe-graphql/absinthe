defmodule Absinthe.Phase.Document.Validation.VariablesOfCorrectTypeTest do
  @phase Absinthe.Phase.Document.Arguments.VariableTypesMatch

  use Absinthe.ValidationPhaseCase, async: true, phase: @phase

  defp error_message(op, variable_name, var_type, arg_type) do
    var = %Absinthe.Blueprint.Input.Variable{name: variable_name}
    @phase.error_message(op, var, var_type, arg_type)
  end

  test "types of variables match types of arguments" do
    {:ok, %{errors: errors}} =
      Absinthe.run(
        """
        query test($intArg: Int!) {
          complicatedArgs {
            stringArgField(stringArg: $intArg)
          }
        }
        """,
        Absinthe.Fixtures.PetsSchema,
        variables: %{"intArg" => 5}
      )

    expected_error_msg = error_message("test", "intArg", "Int", "String")
    assert expected_error_msg in (errors |> Enum.map(& &1.message))
  end

  test "variable type check handles non existent type" do
    {:ok, %{errors: errors}} =
      Absinthe.run(
        """
        query test($intArg: DoesNotExist!) {
          complicatedArgs {
            stringArgField(stringArg: $intArg)
          }
        }
        """,
        Absinthe.Fixtures.PetsSchema,
        variables: %{"intArg" => 5}
      )

    expected_error_msg = "Argument \"stringArg\" has invalid value $intArg."
    assert expected_error_msg in (errors |> Enum.map(& &1.message))
  end

  test "types of variables match types of arguments even when the value is null" do
    {:ok, %{errors: errors}} =
      Absinthe.run(
        """
        query test($intArg: Int) {
          complicatedArgs {
            stringArgField(stringArg: $intArg)
          }
        }
        """,
        Absinthe.Fixtures.PetsSchema,
        variables: %{"intArg" => nil}
      )

    expected_error_msg = error_message("test", "intArg", "Int", "String")
    assert expected_error_msg in (errors |> Enum.map(& &1.message))
  end

  test "types of variables match types of arguments in named fragments" do
    {:ok, %{errors: errors}} =
      Absinthe.run(
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
        Absinthe.Fixtures.PetsSchema,
        variables: %{"intArg" => 5}
      )

    expected_error_msg = error_message("test", "intArg", "Int", "String")
    assert expected_error_msg in (errors |> Enum.map(& &1.message))
  end
end
