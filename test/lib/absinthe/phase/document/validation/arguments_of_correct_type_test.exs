defmodule Absinthe.Phase.Document.Validation.ArgumentsOfCorrectTypeTest do
  use Absinthe.Case, async: true

  @rule Absinthe.Phase.Document.Validation.ArgumentsOfCorrectType

  use Support.Harness.Validation
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
    @rule.error_message(name, inspected_value)
  end
  defp error_message(name, inspected_value, verbose_errors) do
    @rule.error_message(name, inspected_value)
      <> "\n"
      <> Enum.join(verbose_errors, "\n")
  end

  context "Valid values" do

    test "Good int value" do
      assert_passes_rule(@rule,
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
      assert_passes_rule(@rule,
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
      assert_passes_rule(@rule,
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
      assert_passes_rule(@rule,
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
      assert_passes_rule(@rule,
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
      assert_passes_rule(@rule,
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
      assert_passes_rule(@rule,
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
      assert_passes_rule(@rule,
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


  context "Invalid String values" do

    test "Int into String" do
      assert_fails_rule(@rule,
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
      assert_fails_rule(@rule,
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
      assert_fails_rule(@rule,
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
      assert_fails_rule(@rule,
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

  context "Invalid Int values" do

    test "String into Int" do
      assert_fails_rule(@rule,
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
      assert_fails_rule(@rule,
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
      assert_fails_rule(@rule,
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
      assert_fails_rule(@rule,
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
      assert_fails_rule(@rule,
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

  context "Invalid Float values" do

    test "String into Float" do
      assert_fails_rule(@rule,
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
      assert_fails_rule(@rule,
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
      assert_fails_rule(@rule,
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

  context "Invalid Boolean value" do

    test "Int into Boolean" do
      assert_fails_rule(@rule,
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
      assert_fails_rule(@rule,
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
      assert_fails_rule(@rule,
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
      assert_fails_rule(@rule,
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


  context "Invalid ID value" do

    test "Float into ID" do
      assert_fails_rule(@rule,
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
      assert_fails_rule(@rule,
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
      assert_fails_rule(@rule,
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

  context "Invalid Enum value" do

    test "Int into Enum" do
      assert_fails_rule(@rule,
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
      assert_fails_rule(@rule,
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
      assert_fails_rule(@rule,
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
      assert_fails_rule(@rule,
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
      assert_fails_rule(@rule,
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
      assert_fails_rule(@rule,
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

  context "Valid List value" do

    test "Good list value" do
      assert_passes_rule(@rule,
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
      assert_passes_rule(@rule,
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
      assert_passes_rule(@rule,
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
      assert_passes_rule(@rule,
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

  context "Invalid List value" do

    test "Incorrect item type" do
      assert_fails_rule(@rule,
        """
        {
          complicatedArgs {
            stringListArgField(stringListArg: ["one", 2])
          }
        }
        """,
        [],
        [
          bad_argument("stringListArg", "[String]", ~s(["one", 2]), 3,
            [
              @rule.value_error_message(1, "String", "2")
            ]
          )
        ]
      )
    end

    test "Single value of incorrect type" do
      assert_fails_rule(@rule,
        """
        {
          complicatedArgs {
            stringListArgField(stringListArg: 1)
          }
        }
        """,
        [],
        [
          bad_argument("stringListArg", "[String]", "1", 3,
            [
              @rule.value_error_message(0, "[String]", "1")
            ]
          )
        ]
      )
    end

  end

  context "Valid non-nullable value" do

    test "Arg on optional arg" do
      assert_passes_rule(@rule,
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
      assert_passes_rule(@rule,
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
      assert_passes_rule(@rule,
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
      assert_passes_rule(@rule,
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
      assert_passes_rule(@rule,
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
      assert_passes_rule(@rule,
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
      assert_passes_rule(@rule,
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
      assert_passes_rule(@rule,
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
      assert_passes_rule(@rule,
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
      assert_passes_rule(@rule,
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

  context "Invalid non-nullable value" do

    test "Incorrect value type" do
      assert_fails_rule(@rule,
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
      assert_fails_rule(@rule,
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

  context "Valid input object value" do

    test "Optional arg, despite required field in type" do
      assert_passes_rule(@rule,
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
      assert_passes_rule(@rule,
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
      assert_passes_rule(@rule,
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
      assert_passes_rule(@rule,
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

    test "Full object" do
      assert_passes_rule(@rule,
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
      assert_passes_rule(@rule,
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

  context "Invalid input object value" do

    test "Partial object, missing required" do
      assert_fails_rule(@rule,
        """
        {
          complicatedArgs {
            complexArgField(complexArg: { intField: 4 })
          }
        }
        """,
        [],
        [
          bad_argument("complexArg", "ComplexInput", "{intField: 4}", 3,
            [
              @rule.value_error_message("requiredField", "Boolean!", "null")
            ]
          )
        ]
      )
    end

    test "Partial object, invalid field type" do
      assert_fails_rule(@rule,
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
          bad_argument("complexArg", "ComplexInput", ~s({stringListField: ["one", 2], requiredField: true}), 3,
            [
              @rule.value_error_message("stringListField", "[String]", ~s(["one", 2])),
              @rule.value_error_message(1, "String", "2")
            ]
          )
        ]
      )
    end

    test "Partial object, unknown field arg" do
      assert_fails_rule(@rule,
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
        bad_argument("complexArg", "ComplexInput", ~s({requiredField: true, unknownField: "value"}), 3,
          [
            @rule.unknown_field_error_message("unknownField")
          ]
        )
      )
    end

  end

  context "Directive arguments" do

    test "with directives of valid types" do
      assert_passes_rule(@rule,
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
      assert_fails_rule(@rule,
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
