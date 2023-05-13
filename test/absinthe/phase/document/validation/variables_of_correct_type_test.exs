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

    expected_error_msg = error_message("test", "intArg", "Int!", "String")
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

    expected_error_msg = error_message("test", "intArg", "DoesNotExist!", "String")

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

  test "non null types of variables match non null types of arguments" do
    {:ok, %{errors: errors}} =
      Absinthe.run(
        """
        query test($intArg: Int) {
          complicatedArgs {
            nonNullIntArgField(nonNullIntArg: $intArg)
          }
        }
        """,
        Absinthe.Fixtures.PetsSchema,
        variables: %{"intArg" => 5}
      )

    expected_error_msg = error_message("test", "intArg", "Int", "Int!")
    assert expected_error_msg in (errors |> Enum.map(& &1.message))
  end

  test "list types of variables match list types of arguments" do
    result =
      Absinthe.run(
        """
        query test($stringListArg: [String!]) {
          complicatedArgs {
            stringListArgField(stringListArg: $stringListArg)
          }
        }
        """,
        Absinthe.Fixtures.PetsSchema,
        variables: %{"stringListArg" => ["a"]}
      )

    assert {:ok, %{data: %{"complicatedArgs" => nil}}} = result
  end

  test "variable can be nullable for non-nullable argument with default" do
    result =
      Absinthe.run(
        """
        query booleanArgQueryWithDefault($booleanArg: Boolean) {
          complicatedArgs {
            optionalNonNullBooleanArgField(optionalBooleanArg: $booleanArg)
          }
        }
        """,
        Absinthe.Fixtures.PetsSchema
      )

    assert {:ok, %{data: %{"complicatedArgs" => nil}}} = result
  end

  test "variable with default can be nullable for non-nullable argument" do
    result =
      Absinthe.run(
        """
        query booleanArgQueryWithDefault($booleanArg: Boolean = true) {
          complicatedArgs {
            nonNullBooleanArgField(nonNullBooleanArg: $booleanArg)
          }
        }
        """,
        Absinthe.Fixtures.PetsSchema
      )

    assert {:ok, %{data: %{"complicatedArgs" => nil}}} = result
  end
end
