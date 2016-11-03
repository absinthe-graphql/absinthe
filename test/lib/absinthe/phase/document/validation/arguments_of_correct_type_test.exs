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

  describe "Valid values" do

    it "Good int value" do
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


    it "Good boolean value" do
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

    it "Good string value" do
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

    it "Good float value" do
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

    it "Int into Float" do
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

    it "Int into ID" do
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

    it "String into ID" do
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

    it "Good enum value" do
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


  describe "Invalid String values" do

    it "Int into String" do
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

    it "Float into String" do
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

    it "Boolean into String" do
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

    it "Unquoted String into String" do
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

  describe "Invalid Int values" do

    it "String into Int" do
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

    it "Big Int into Int" do
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

    it "Unquoted String into Int" do
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

    it "Simple Float into Int" do
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

    it "Float into Int" do
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

  describe "Invalid Float values" do

    it "String into Float" do
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

    it "Boolean into Float" do
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

    it "Unquoted into Float" do
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

  describe "Invalid Boolean value" do

    it "Int into Boolean" do
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

    it "Float into Boolean" do
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

    it "String into Boolean" do
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

    it "Unquoted into Boolean" do
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


  describe "Invalid ID value" do

    it "Float into ID" do
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

    it "Boolean into ID" do
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

    it "Unquoted into ID" do
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

  describe "Invalid Enum value" do

    it "Int into Enum" do
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

    it "Float into Enum" do
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

    it "String into Enum" do
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

    it "Boolean into Enum" do
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

    it "Unknown Enum Value into Enum" do
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

    it "Different case Enum Value into Enum" do
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

  describe "Valid List value" do

    it "Good list value" do
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

    it "Empty list value" do
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

    it "Single value into List" do
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

  end

  describe "Invalid List value" do

    it "Incorrect item type" do
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

    it "Single value of incorrect type" do
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
              @rule.value_error_message(0, "String", "1")
            ]
          )
        ]
      )
    end

  end

  describe "Valid non-nullable value" do

    it "Arg on optional arg" do
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

    it "No Arg on optional arg" do
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

    it "Multiple args" do
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

    it "Multiple args reverse order" do
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

    it "No args on multiple optional" do
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

    it "One arg on multiple optional" do
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

    it "Second arg on multiple optional" do
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

    it "Multiple reqs on mixedList" do
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

    it "Multiple reqs and one opt on mixedList" do
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

    it "All reqs and opts on mixedList" do
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

  describe "Invalid non-nullable value" do

    it "Incorrect value type" do
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

    it "Incorrect value and missing argument" do
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

  describe "Valid input object value" do

    it "Optional arg, despite required field in type" do
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

    it "Partial object, only required" do
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

    it "Partial object, required field can be falsey" do
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

    it "Partial object, including required" do
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

    it "Full object" do
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

    it "Full object with fields in different order" do
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

  describe "Invalid input object value" do

    it "Partial object, missing required" do
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

    it "Partial object, invalid field type" do
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

    it "Partial object, unknown field arg" do
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

    it "Scalar type for input object" do
      assert_fails_rule(@rule,
        """
        {
          complicatedArgs {
            complexArgField(complexArg: true)
          }
        }
        """,
        [],
        bad_argument("complexArg", "ComplexInput", ~s(true), 3,
          [
            @rule.expected_type_error_message("ComplexInput", "true")
          ]
        )
      )
    end

  end

  describe "Directive arguments" do

    it "with directives of valid types" do
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

    it "with directive with incorrect types" do
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
