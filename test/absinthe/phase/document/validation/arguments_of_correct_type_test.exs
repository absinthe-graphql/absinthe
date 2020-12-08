defmodule Absinthe.Phase.Document.Validation.ArgumentsOfCorrectTypeTest do
  @phase Absinthe.Phase.Document.Validation.ArgumentsOfCorrectType

  use Absinthe.ValidationPhaseCase,
    phase: @phase,
    async: true

  alias Absinthe.{Blueprint}

  defp bad_argument(name, _expected_type, inspected_value, line, verbose_errors) do
    bad_value(
      Blueprint.Input.Argument,
      error_message(name, inspected_value, verbose_errors),
      line,
      name: name
    )
  end

  defp error_message(name, inspected_value, []) do
    @phase.error_message(name, inspected_value)
  end

  defp error_message(name, inspected_value, verbose_errors) do
    @phase.error_message(name, inspected_value) <> "\n" <> Enum.join(verbose_errors, "\n")
  end

  describe "Valid values" do
    test "Good int value" do
      assert_passes_validation(
        """
        {
          complicatedArgs {
            intArgField(intArg: 2)
          }
        }
        """,
        []
      )
    end

    test "Good boolean value" do
      assert_passes_validation(
        """
        {
          complicatedArgs {
            booleanArgField(booleanArg: true)
          }
        }
        """,
        []
      )
    end

    test "Good string value" do
      assert_passes_validation(
        """
        {
          complicatedArgs {
            stringArgField(stringArg: "foo")
          }
        }
        """,
        []
      )
    end

    test "Good float value" do
      assert_passes_validation(
        """
        {
          complicatedArgs {
            floatArgField(floatArg: 1.1)
          }
        }
        """,
        []
      )
    end

    test "Int into Float" do
      assert_passes_validation(
        """
        {
          complicatedArgs {
            floatArgField(floatArg: 1)
          }
        }
        """,
        []
      )
    end

    test "Int into ID" do
      assert_passes_validation(
        """
        {
          complicatedArgs {
            idArgField(idArg: 1)
          }
        }
        """,
        []
      )
    end

    test "String into ID" do
      assert_passes_validation(
        """
        {
          complicatedArgs {
            idArgField(idArg: "someIdString")
          }
        }
        """,
        []
      )
    end

    test "Good enum value" do
      assert_passes_validation(
        """
        {
          dog {
            doesKnowCommand(dogCommand: SIT)
          }
        }
        """,
        []
      )
    end
  end

  describe "Invalid String values" do
    test "Int into String" do
      assert_fails_validation(
        """
        {
          complicatedArgs {
            stringArgField(stringArg: 1)
          }
        }
        """,
        [],
        bad_argument("stringArg", "String", "1", 3, [])
      )
    end

    test "Float into String" do
      assert_fails_validation(
        """
        {
          complicatedArgs {
            stringArgField(stringArg: 1.0)
          }
        }
        """,
        [],
        bad_argument("stringArg", "String", "1.0", 3, [])
      )
    end

    test "Boolean into String" do
      assert_fails_validation(
        """
        {
          complicatedArgs {
            stringArgField(stringArg: true)
          }
        }
        """,
        [],
        bad_argument("stringArg", "String", "true", 3, [])
      )
    end

    test "Unquoted String into String" do
      assert_fails_validation(
        """
        {
          complicatedArgs {
            stringArgField(stringArg: BAR)
          }
        }
        """,
        [],
        bad_argument("stringArg", "String", "BAR", 3, [])
      )
    end
  end

  describe "Invalid Int values" do
    test "String into Int" do
      assert_fails_validation(
        """
        {
          complicatedArgs {
            intArgField(intArg: "3")
          }
        }
        """,
        [],
        bad_argument("intArg", "Int", ~s("3"), 3, [])
      )
    end

    test "Big Int into Int" do
      assert_fails_validation(
        """
        {
          complicatedArgs {
            intArgField(intArg: 829384293849283498239482938)
          }
        }
        """,
        [],
        bad_argument("intArg", "Int", "829384293849283498239482938", 3, [])
      )
    end

    test "Unquoted String into Int" do
      assert_fails_validation(
        """
        {
          complicatedArgs {
            intArgField(intArg: FOO)
          }
        }
        """,
        [],
        bad_argument("intArg", "Int", "FOO", 3, [])
      )
    end

    test "Simple Float into Int" do
      assert_fails_validation(
        """
        {
          complicatedArgs {
            intArgField(intArg: 3.0)
          }
        }
        """,
        [],
        bad_argument("intArg", "Int", "3.0", 3, [])
      )
    end

    test "Float into Int" do
      assert_fails_validation(
        """
        {
          complicatedArgs {
            intArgField(intArg: 3.333)
          }
        }
        """,
        [],
        bad_argument("intArg", "Int", "3.333", 3, [])
      )
    end
  end

  describe "Invalid Float values" do
    test "String into Float" do
      assert_fails_validation(
        """
        {
          complicatedArgs {
            floatArgField(floatArg: "3.333")
          }
        }
        """,
        [],
        bad_argument("floatArg", "Float", ~s("3.333"), 3, [])
      )
    end

    test "Boolean into Float" do
      assert_fails_validation(
        """
        {
          complicatedArgs {
            floatArgField(floatArg: true)
          }
        }
        """,
        [],
        bad_argument("floatArg", "Float", "true", 3, [])
      )
    end

    test "Unquoted into Float" do
      assert_fails_validation(
        """
        {
          complicatedArgs {
            floatArgField(floatArg: FOO)
          }
        }
        """,
        [],
        bad_argument("floatArg", "Float", "FOO", 3, [])
      )
    end
  end

  describe "Invalid Boolean value" do
    test "Int into Boolean" do
      assert_fails_validation(
        """
        {
          complicatedArgs {
            booleanArgField(booleanArg: 2)
          }
        }
        """,
        [],
        bad_argument("booleanArg", "Boolean", "2", 3, [])
      )
    end

    test "Float into Boolean" do
      assert_fails_validation(
        """
        {
          complicatedArgs {
            booleanArgField(booleanArg: 1.0)
          }
        }
        """,
        [],
        bad_argument("booleanArg", "Boolean", "1.0", 3, [])
      )
    end

    test "String into Boolean" do
      assert_fails_validation(
        """
        {
          complicatedArgs {
            booleanArgField(booleanArg: "true")
          }
        }
        """,
        [],
        bad_argument("booleanArg", "Boolean", ~s("true"), 3, [])
      )
    end

    test "Unquoted into Boolean" do
      assert_fails_validation(
        """
        {
          complicatedArgs {
            booleanArgField(booleanArg: TRUE)
          }
        }
        """,
        [],
        bad_argument("booleanArg", "Boolean", "TRUE", 3, [])
      )
    end
  end

  describe "Invalid ID value" do
    test "Float into ID" do
      assert_fails_validation(
        """
        {
          complicatedArgs {
            idArgField(idArg: 1.0)
          }
        }
        """,
        [],
        bad_argument("idArg", "ID", "1.0", 3, [])
      )
    end

    test "Boolean into ID" do
      assert_fails_validation(
        """
        {
          complicatedArgs {
            idArgField(idArg: true)
          }
        }
        """,
        [],
        bad_argument("idArg", "ID", "true", 3, [])
      )
    end

    test "Unquoted into ID" do
      assert_fails_validation(
        """
        {
          complicatedArgs {
            idArgField(idArg: SOMETHING)
          }
        }
        """,
        [],
        bad_argument("idArg", "ID", "SOMETHING", 3, [])
      )
    end
  end

  describe "Invalid Enum value" do
    test "Int into Enum" do
      assert_fails_validation(
        """
        {
          dog {
            doesKnowCommand(dogCommand: 2)
          }
        }
        """,
        [],
        bad_argument("dogCommand", "DogCommand", "2", 3, [])
      )
    end

    test "Float into Enum" do
      assert_fails_validation(
        """
        {
          dog {
            doesKnowCommand(dogCommand: 1.0)
          }
        }
        """,
        [],
        bad_argument("dogCommand", "DogCommand", "1.0", 3, [])
      )
    end

    test "String into Enum" do
      assert_fails_validation(
        """
        {
          dog {
            doesKnowCommand(dogCommand: "SIT")
          }
        }
        """,
        [],
        bad_argument("dogCommand", "DogCommand", ~s("SIT"), 3, [])
      )
    end

    test "Boolean into Enum" do
      assert_fails_validation(
        """
        {
          dog {
            doesKnowCommand(dogCommand: true)
          }
        }
        """,
        [],
        bad_argument("dogCommand", "DogCommand", "true", 3, [])
      )
    end

    test "Unknown Enum Value into Enum" do
      assert_fails_validation(
        """
        {
          dog {
            doesKnowCommand(dogCommand: JUGGLE)
          }
        }
        """,
        [],
        bad_argument("dogCommand", "DogCommand", "JUGGLE", 3, [])
      )
    end

    test "Different case Enum Value into Enum" do
      assert_fails_validation(
        """
        {
          dog {
            doesKnowCommand(dogCommand: sit)
          }
        }
        """,
        [],
        bad_argument("dogCommand", "DogCommand", "sit", 3, [])
      )
    end
  end

  describe "Valid List value" do
    test "Good list value" do
      assert_passes_validation(
        """
        {
          complicatedArgs {
            stringListArgField(stringListArg: ["one", "two"])
          }
        }
        """,
        []
      )
    end

    test "Empty list value" do
      assert_passes_validation(
        """
        {
          complicatedArgs {
            stringListArgField(stringListArg: [])
          }
        }
        """,
        []
      )
    end

    test "Single value into List" do
      assert_passes_validation(
        """
        {
          complicatedArgs {
            stringListArgField(stringListArg: "one")
          }
        }
        """,
        []
      )
    end

    test "List of List" do
      assert_passes_validation(
        """
        {
          complicatedArgs {
            stringListOfListArgField(stringListOfListArg: [["one"], ["two", "three"]])
          }
        }
        """,
        []
      )
    end
  end

  describe "Invalid List value" do
    test "Incorrect item type" do
      assert_fails_validation(
        """
        {
          complicatedArgs {
            stringListArgField(stringListArg: ["one", 2])
          }
        }
        """,
        [],
        [
          bad_argument("stringListArg", "[String]", ~s(["one", 2]), 3, [
            @phase.value_error_message(1, "String", "2")
          ])
        ]
      )
    end

    test "Single value of incorrect type" do
      assert_fails_validation(
        """
        {
          complicatedArgs {
            stringListArgField(stringListArg: 1)
          }
        }
        """,
        [],
        [
          bad_argument("stringListArg", "[String]", "1", 3, [
            @phase.value_error_message(0, "[String]", "1")
          ])
        ]
      )
    end
  end

  describe "Valid non-nullable value" do
    test "Arg on optional arg" do
      assert_passes_validation(
        """
        {
          dog {
            isHousetrained(atOtherHomes: true)
          }
        }
        """,
        []
      )
    end

    test "No Arg on optional arg" do
      assert_passes_validation(
        """
        {
          dog {
            isHousetrained
          }
        }
        """,
        []
      )
    end

    test "Multiple args" do
      assert_passes_validation(
        """
        {
          complicatedArgs {
            multipleReqs(req1: 1, req2: 2)
          }
        }
        """,
        []
      )
    end

    test "Multiple args reverse order" do
      assert_passes_validation(
        """
        {
          complicatedArgs {
            multipleReqs(req2: 2, req1: 1)
          }
        }
        """,
        []
      )
    end

    test "No args on multiple optional" do
      assert_passes_validation(
        """
        {
          complicatedArgs {
            multipleOpts
          }
        }
        """,
        []
      )
    end

    test "One arg on multiple optional" do
      assert_passes_validation(
        """
        {
          complicatedArgs {
            multipleOpts(opt1: 1)
          }
        }
        """,
        []
      )
    end

    test "Second arg on multiple optional" do
      assert_passes_validation(
        """
        {
          complicatedArgs {
            multipleOpts(opt2: 1)
          }
        }
        """,
        []
      )
    end

    test "Multiple reqs on mixedList" do
      assert_passes_validation(
        """
        {
          complicatedArgs {
            multipleOptAndReq(req1: 3, req2: 4)
          }
        }
        """,
        []
      )
    end

    test "Multiple reqs and one opt on mixedList" do
      assert_passes_validation(
        """
        {
          complicatedArgs {
            multipleOptAndReq(req1: 3, req2: 4, opt1: 5)
          }
        }
        """,
        []
      )
    end

    test "All reqs and opts on mixedList" do
      assert_passes_validation(
        """
        {
          complicatedArgs {
            multipleOptAndReq(req1: 3, req2: 4, opt1: 5, opt2: 6)
          }
        }
        """,
        []
      )
    end
  end

  describe "Invalid non-nullable value" do
    test "Incorrect value type" do
      assert_fails_validation(
        """
        {
          complicatedArgs {
            multipleReqs(req2: "two", req1: "one")
          }
        }
        """,
        [],
        [
          bad_argument("req2", "Int!", ~s("two"), 3, []),
          bad_argument("req1", "Int!", ~s("one"), 3, [])
        ]
      )
    end

    test "Incorrect value and missing argument" do
      assert_fails_validation(
        """
        {
          complicatedArgs {
            multipleReqs(req1: "one")
          }
        }
        """,
        [],
        bad_argument("req1", "Int!", ~s("one"), 3, [])
      )
    end
  end

  describe "Valid input object value" do
    test "Optional arg, despite required field in type" do
      assert_passes_validation(
        """
        {
          complicatedArgs {
            complexArgField
          }
        }
        """,
        []
      )
    end

    test "Partial object, only required" do
      assert_passes_validation(
        """
        {
          complicatedArgs {
            complexArgField(complexArg: { requiredField: true })
          }
        }
        """,
        []
      )
    end

    test "Partial object, required field can be falsey" do
      assert_passes_validation(
        """
        {
          complicatedArgs {
            complexArgField(complexArg: { requiredField: false })
          }
        }
        """,
        []
      )
    end

    test "Partial object, including required" do
      assert_passes_validation(
        """
        {
          complicatedArgs {
            complexArgField(complexArg: { requiredField: true, intField: 4 })
          }
        }
        """,
        []
      )
    end

    test "Partial object, list with correct value" do
      assert_passes_validation(
        """
        {
          complicatedArgs {
            complexArgField(complexArgList: [{ requiredField: true }])
          }
        }
        """,
        []
      )
    end

    test "Partial object, list with bad value" do
      assert_fails_validation(
        """
        {
          complicatedArgs {
            complexArgField(complexArgList: [2])
          }
        }
        """,
        [],
        [
          bad_argument("complexArgList", "[ComplexInput]", "[2]", 3, [
            @phase.value_error_message(0, "ComplexInput", "2")
          ])
        ]
      )
    end

    test "Full object" do
      assert_passes_validation(
        """
        {
          complicatedArgs {
            complexArgField(complexArg: {
              requiredField: true,
              intField: 4,
              stringField: "foo",
              booleanField: false,
              stringListField: ["one", "two"]
            })
          }
        }
        """,
        []
      )
    end

    test "Full object with fields in different order" do
      assert_passes_validation(
        """
        {
          complicatedArgs {
            complexArgField(complexArg: {
              stringListField: ["one", "two"],
              booleanField: false,
              requiredField: true,
              stringField: "foo",
              intField: 4,
            })
          }
        }
        """,
        []
      )
    end
  end

  describe "Invalid input object value" do
    test "Partial object, missing required" do
      assert_fails_validation(
        """
        {
          complicatedArgs {
            complexArgField(complexArg: { intField: 4 })
          }
        }
        """,
        [],
        [
          bad_argument("complexArg", "ComplexInput", "{intField: 4}", 3, [
            @phase.value_error_message("requiredField", "Boolean!", "null")
          ])
        ]
      )
    end

    test "Partial object, invalid field type" do
      assert_fails_validation(
        """
        {
          complicatedArgs {
            complexArgField(complexArg: {
              stringListField: ["one", 2],
              requiredField: true,
            })
          }
        }
        """,
        [],
        [
          bad_argument(
            "complexArg",
            "ComplexInput",
            ~s({stringListField: ["one", 2], requiredField: true}),
            3,
            [
              @phase.value_error_message("stringListField", "[String]", ~s(["one", 2])),
              @phase.value_error_message(1, "String", "2")
            ]
          )
        ]
      )
    end

    test "Partial object, unknown field arg without suggestion" do
      assert_fails_validation(
        """
        {
          complicatedArgs {
            complexArgField(complexArg: {
              requiredField: true,
              unknownField: "value"
            })
          }
        }
        """,
        [],
        bad_argument(
          "complexArg",
          "ComplexInput",
          ~s({requiredField: true, unknownField: "value"}),
          3,
          [
            @phase.unknown_field_error_message("unknownField")
          ]
        )
      )
    end

    test "Partial object, unknown field arg with suggestion" do
      assert_fails_validation(
        """
        {
          complicatedArgs {
            complexArgField(complexArg: {
              requiredField: true,
              strinField: "value"
            })
          }
        }
        """,
        [],
        bad_argument(
          "complexArg",
          "ComplexInput",
          ~s({requiredField: true, strinField: "value"}),
          3,
          [
            @phase.unknown_field_error_message("strinField", [
              "string_list_field",
              "int_field",
              "string_field"
            ])
          ]
        )
      )
    end
  end

  describe "Invalid Custom Scalar value" do
    test "Invalid scalar input on mutation, no suggestion" do
      assert_fails_validation(
        """
        mutation($scalarInput: CustomScalar) {
          createDog(customScalarInput: $scalarInput)
        }
        """,
        [
          variables: %{
            "scalarInput" => [
              %{
                "foo" => "BAR"
              }
            ]
          }
        ],
        [
          bad_argument(
            "customScalarInput",
            "CustomScalar",
            ~s($scalarInput),
            2,
            [@phase.unknown_field_error_message("foo")]
          )
        ]
      )
    end
  end

  describe "Directive arguments" do
    test "with directives of valid types" do
      assert_passes_validation(
        """
        {
          dog @include(if: true) {
            name
          }
          human @skip(if: false) {
            name
          }
        }
        """,
        []
      )
    end

    test "with directive with incorrect types" do
      assert_fails_validation(
        """
        {
          dog @include(if: "yes") {
            name @skip(if: ENUM)
          }
        }
        """,
        [],
        [
          bad_argument("if", "Boolean!", ~s("yes"), 2, []),
          bad_argument("if", "Boolean!", "ENUM", 3, [])
        ]
      )
    end
  end
end
