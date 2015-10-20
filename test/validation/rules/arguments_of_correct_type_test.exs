defmodule Validation.ArgumentsOfCorrectTypeTest do
  use ExSpec, async: true

  alias ExGraphQL.Validation.Rules.ArgumentsOfCorrectType
  import Validation.TestHelper

  def bad_value_error(name, type, value, _line, _column) do
    "Argument \"#{name}\" expected type \"#{type}\" but got: \"#{value}\"."
  end

  describe "Valid values" do

    it "Good int value" do
      assert_passes_rule ArgumentsOfCorrectType, """
        {
          complicatedArgs {
            intArgField(intArg: 2)
          }
        }
      """
    end

    it "Good boolean value" do
      assert_passes_rule ArgumentsOfCorrectType, """
        {
          complicatedArgs {
            booleanArgField(booleanArg: true)
          }
        }
      """
    end

    it "Good string value" do
      assert_passes_rule ArgumentsOfCorrectType, """
        {
          complicatedArgs {
            stringArgField(stringArg: "foo")
          }
        }
      """
    end

    it "Good float value" do
      assert_passes_rule ArgumentsOfCorrectType, """
        {
          complicatedArgs {
            floatArgField(floatArg: 1.1)
          }
        }
      """
    end

    it "Int into Float" do
      assert_passes_rule ArgumentsOfCorrectType, """
        {
          complicatedArgs {
            floatArgField(floatArg: 1)
          }
        }
      """
    end

    it "Int into ID" do
      assert_passes_rule ArgumentsOfCorrectType, """
        {
          complicatedArgs {
            idArgField(idArg: 1)
          }
        }
      """
    end

    it "String into ID" do
      assert_passes_rule ArgumentsOfCorrectType, """
        {
          complicatedArgs {
            idArgField(idArg: "someIdString")
          }
        }
      """
    end

    it "Good enum value" do
      assert_passes_rule ArgumentsOfCorrectType, """
        {
          dog {
            doesKnowCommand(dogCommand: SIT)
          }
        }
      """
    end

  end


  describe "Invalid String values" do

    it "Int into String" do
      assert_fails_rule ArgumentsOfCorrectType, """
        {
          complicatedArgs {
            stringArgField(stringArg: 1)
          }
        }
      """, [
        bad_value_error("stringArg", "String", "1", 4, 39)
      ]
    end

    it "Float into String" do
      assert_fails_rule ArgumentsOfCorrectType, """
        {
          complicatedArgs {
            stringArgField(stringArg: 1.0)
          }
        }
      """, [
        bad_value_error("stringArg", "String", "1.0", 4, 39)
      ]
    end

    it "Boolean into String" do
      assert_fails_rule ArgumentsOfCorrectType, """
        {
          complicatedArgs {
            stringArgField(stringArg: true)
          }
        }
      """, [
        bad_value_error("stringArg", "String", "true", 4, 39)
      ]
    end

    it "Unquoted String into String" do
      assert_fails_rule ArgumentsOfCorrectType, """
        {
          complicatedArgs {
            stringArgField(stringArg: BAR)
          }
        }
      """, [
        bad_value_error("stringArg", "String", "BAR", 4, 39)
      ]
    end

  end


  describe "Invalid Int values" do

    it "String into Int" do
      assert_fails_rule ArgumentsOfCorrectType, """
        {
          complicatedArgs {
            intArgField(intArg: "3")
          }
        }
      """, [
        bad_value_error("intArg", "Int", "\"3\"", 4, 33)
      ]
    end

    it "Big Int into Int" do
      assert_fails_rule ArgumentsOfCorrectType, """
        {
          complicatedArgs {
            intArgField(intArg: 829384293849283498239482938)
          }
        }
      """, [
        bad_value_error("intArg", "Int", "829384293849283498239482938", 4, 33)
      ]
    end

    it "Unquoted String into Int" do
      assert_fails_rule ArgumentsOfCorrectType, """
        {
          complicatedArgs {
            intArgField(intArg: FOO)
          }
        }
      """, [
        bad_value_error("intArg", "Int", "FOO", 4, 33)
      ]
    end

    it "Simple Float into Int" do
      assert_fails_rule ArgumentsOfCorrectType, """
        {
          complicatedArgs {
            intArgField(intArg: 3.0)
          }
        }
      """, [
        bad_value_error("intArg", "Int", "3.0", 4, 33)
      ]
    end

    it "Float into Int" do
      assert_fails_rule ArgumentsOfCorrectType, """
        {
          complicatedArgs {
            intArgField(intArg: 3.333)
          }
        }
      """, [
        bad_value_error("intArg", "Int", "3.333", 4, 33)
      ]
    end

  end


  describe "Invalid Float values" do

    it "String into Float" do
      assert_fails_rule ArgumentsOfCorrectType, """
        {
          complicatedArgs {
            floatArgField(floatArg: "3.333")
          }
        }
      """, [
        bad_value_error("floatArg", "Float", "\"3.333\"", 4, 37)
      ]
    end

    it "Boolean into Float" do
      assert_fails_rule ArgumentsOfCorrectType, """
        {
          complicatedArgs {
            floatArgField(floatArg: true)
          }
        }
      """, [
        bad_value_error("floatArg", "Float", "true", 4, 37)
      ]
    end

    it "Unquoted into Float" do
      assert_fails_rule ArgumentsOfCorrectType, """
        {
          complicatedArgs {
            floatArgField(floatArg: FOO)
          }
        }
      """, [
        bad_value_error("floatArg", "Float", "FOO", 4, 37)
      ]
    end

  end


  describe "Invalid Boolean value" do

    it "Int into Boolean" do
      assert_fails_rule ArgumentsOfCorrectType, """
        {
          complicatedArgs {
            booleanArgField(booleanArg: 2)
          }
        }
      """, [
        bad_value_error("booleanArg", "Boolean", "2", 4, 41)
      ]
    end

    it "Float into Boolean" do
      assert_fails_rule ArgumentsOfCorrectType, """
        {
          complicatedArgs {
            booleanArgField(booleanArg: 1.0)
          }
        }
      """, [
        bad_value_error("booleanArg", "Boolean", "1.0", 4, 41)
      ]
    end

    it "String into Boolean" do
      assert_fails_rule ArgumentsOfCorrectType, """
        {
          complicatedArgs {
            booleanArgField(booleanArg: "true")
          }
        }
      """, [
        bad_value_error("booleanArg", "Boolean", "\"true\"", 4, 41)
      ]
    end

    it "Unquoted into Boolean" do
      assert_fails_rule ArgumentsOfCorrectType, """
        {
          complicatedArgs {
            booleanArgField(booleanArg: TRUE)
          }
        }
      """, [
        bad_value_error("booleanArg", "Boolean", "TRUE", 4, 41)
      ]
    end

  end


  describe "Invalid ID value" do

    it "Float into ID" do
      assert_fails_rule ArgumentsOfCorrectType, """
        {
          complicatedArgs {
            idArgField(idArg: 1.0)
          }
        }
      """, [
        bad_value_error("idArg", "ID", "1.0", 4, 31)
      ]
    end

    it "Boolean into ID" do
      assert_fails_rule ArgumentsOfCorrectType, """
        {
          complicatedArgs {
            idArgField(idArg: true)
          }
        }
      """, [
        bad_value_error("idArg", "ID", "true", 4, 31)
      ]
    end

    it "Unquoted into ID" do
      assert_fails_rule ArgumentsOfCorrectType, """
        {
          complicatedArgs {
            idArgField(idArg: SOMETHING)
          }
        }
      """, [
        bad_value_error("idArg", "ID", "SOMETHING", 4, 31)
      ]
    end

  end


  describe "Invalid Enum value" do

    it "Int into Enum" do
      assert_fails_rule ArgumentsOfCorrectType, """
        {
          dog {
            doesKnowCommand(dogCommand: 2)
          }
        }
      """, [
        bad_value_error("dogCommand", "DogCommand", "2", 4, 41)
      ]
    end

    it "Float into Enum" do
      assert_fails_rule ArgumentsOfCorrectType, """
        {
          dog {
            doesKnowCommand(dogCommand: 1.0)
          }
        }
      """, [
        bad_value_error("dogCommand", "DogCommand", "1.0", 4, 41)
      ]
    end

    it "String into Enum" do
      assert_fails_rule ArgumentsOfCorrectType, """
        {
          dog {
            doesKnowCommand(dogCommand: "SIT")
          }
        }
      """, [
        bad_value_error("dogCommand", "DogCommand", "\"SIT\"", 4, 41)
      ]
    end

    it "Boolean into Enum" do
      assert_fails_rule ArgumentsOfCorrectType, """
        {
          dog {
            doesKnowCommand(dogCommand: true)
          }
        }
      """, [
        bad_value_error("dogCommand", "DogCommand", "true", 4, 41)
      ]
    end

    it "Unknown Enum Value into Enum" do
      assert_fails_rule ArgumentsOfCorrectType, """
        {
          dog {
            doesKnowCommand(dogCommand: JUGGLE)
          }
        }
      """, [
        bad_value_error("dogCommand", "DogCommand", "JUGGLE", 4, 41)
      ]
    end

    it "Different case Enum Value into Enum" do
      assert_fails_rule ArgumentsOfCorrectType, """
        {
          dog {
            doesKnowCommand(dogCommand: sit)
          }
        }
      """, [
        bad_value_error("dogCommand", "DogCommand", "sit", 4, 41)
      ]
    end

  end


  describe "Valid List value" do

    it "Good list value" do
      assert_passes_rule ArgumentsOfCorrectType, """
        {
          complicatedArgs {
            stringListArgField(stringListArg: ["one", "two"])
          }
        }
      """
    end

    it "Empty list value" do
      assert_passes_rule ArgumentsOfCorrectType, """
        {
          complicatedArgs {
            stringListArgField(stringListArg: [])
          }
        }
      """
    end

    it "Single value into List" do
      assert_passes_rule ArgumentsOfCorrectType, """
        {
          complicatedArgs {
            stringListArgField(stringListArg: "one")
          }
        }
      """
    end

  end


  describe "Invalid List value" do

    it "Incorrect item type" do
      assert_fails_rule ArgumentsOfCorrectType, """
        {
          complicatedArgs {
            stringListArgField(stringListArg: ["one", 2])
          }
        }
      """, [
        bad_value_error("stringListArg", "[String]", "[\"one\", 2]", 4, 47),
      ]
    end

    it "Single value of incorrect type" do
      assert_fails_rule ArgumentsOfCorrectType, """
        {
          complicatedArgs {
            stringListArgField(stringListArg: 1)
          }
        }
      """, [
        bad_value_error("stringListArg", "[String]", "1", 4, 47),
      ]
    end

  end


  describe "Valid non-nullable value" do

    it "Arg on optional arg" do
      assert_passes_rule ArgumentsOfCorrectType, """
        {
          dog {
            isHousetrained(atOtherHomes: true)
          }
        }
      """
    end

    it "No Arg on optional arg" do
      assert_passes_rule ArgumentsOfCorrectType, """
        {
          dog {
            isHousetrained
          }
        }
      """
    end

    it "Multiple args" do
      assert_passes_rule ArgumentsOfCorrectType, """
        {
          complicatedArgs {
            multipleReqs(req1: 1, req2: 2)
          }
        }
      """
    end

    it "Multiple args reverse order" do
      assert_passes_rule ArgumentsOfCorrectType, """
        {
          complicatedArgs {
            multipleReqs(req2: 2, req1: 1)
          }
        }
      """
    end

    it "No args on multiple optional" do
      assert_passes_rule ArgumentsOfCorrectType, """
        {
          complicatedArgs {
            multipleOpts
          }
        }
      """
    end

    it "One arg on multiple optional" do
      assert_passes_rule ArgumentsOfCorrectType, """
        {
          complicatedArgs {
            multipleOpts(opt1: 1)
          }
        }
      """
    end

    it "Second arg on multiple optional" do
      assert_passes_rule ArgumentsOfCorrectType, """
        {
          complicatedArgs {
            multipleOpts(opt2: 1)
          }
        }
      """
    end

    it "Multiple reqs on mixedList" do
      assert_passes_rule ArgumentsOfCorrectType, """
        {
          complicatedArgs {
            multipleOptAndReq(req1: 3, req2: 4)
          }
        }
      """
    end

    it "Multiple reqs and one opt on mixedList" do
      assert_passes_rule ArgumentsOfCorrectType, """
        {
          complicatedArgs {
            multipleOptAndReq(req1: 3, req2: 4, opt1: 5)
          }
        }
      """
    end

    it "All reqs and opts on mixedList" do
      assert_passes_rule ArgumentsOfCorrectType, """
        {
          complicatedArgs {
            multipleOptAndReq(req1: 3, req2: 4, opt1: 5, opt2: 6)
          }
        }
      """
    end

  end


  describe "Invalid non-nullable value" do

    @tag :current
    it "Incorrect value type" do
      assert_fails_rule ArgumentsOfCorrectType, """
        {
          complicatedArgs {
            multipleReqs(req2: "two", req1: "one")
          }
        }
      """, [
        bad_value_error("req2", "Int!", "\"two\"", 4, 32),
        bad_value_error("req1", "Int!", "\"one\"", 4, 45),
      ]
    end

    it "Incorrect value and missing argument" do
      assert_fails_rule ArgumentsOfCorrectType, """
        {
          complicatedArgs {
            multipleReqs(req1: "one")
          }
        }
      """, [
        bad_value_error("req1", "Int!", "\"one\"", 4, 32),
      ]
    end

  end


  describe "Valid input object value" do

    it "Optional arg, despite required field in type" do
      assert_passes_rule ArgumentsOfCorrectType, """
        {
          complicatedArgs {
            complexArgField
          }
        }
      """
    end

    it "Partial object, only required" do
      assert_passes_rule ArgumentsOfCorrectType, """
        {
          complicatedArgs {
            complexArgField(complexArg: { requiredField: true })
          }
        }
      """
    end

    it "Partial object, required field can be falsey" do
      assert_passes_rule ArgumentsOfCorrectType, """
        {
          complicatedArgs {
            complexArgField(complexArg: { requiredField: false })
          }
        }
      """
    end

    it "Partial object, including required" do
      assert_passes_rule ArgumentsOfCorrectType, """
        {
          complicatedArgs {
            complexArgField(complexArg: { requiredField: true, intField: 4 })
          }
        }
      """
    end

    it "Full object" do
      assert_passes_rule ArgumentsOfCorrectType, """
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
      """
    end

    it "Full object with fields in different order" do
      assert_passes_rule ArgumentsOfCorrectType, """
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
      """
    end

  end


  describe "Invalid input object value" do

    it "Partial object, missing required" do
      assert_fails_rule ArgumentsOfCorrectType, """
        {
          complicatedArgs {
            complexArgField(complexArg: { intField: 4 })
          }
        }
      """, [
        bad_value_error("complexArg", "ComplexInput", "{intField: 4}", 4, 41),
      ]
    end

    it "Partial object, invalid field type" do
      assert_fails_rule ArgumentsOfCorrectType, """
        {
          complicatedArgs {
            complexArgField(complexArg: {
              stringListField: ["one", 2],
              requiredField: true,
            })
          }
        }
      """, [
        bad_value_error(
          "complexArg",
          "ComplexInput",
          "{stringListField: [\"one\", 2], requiredField: true}",
          4,
          41
        ),
      ]
    end

    it "Partial object, unknown field arg" do
      assert_fails_rule ArgumentsOfCorrectType, """
        {
          complicatedArgs {
            complexArgField(complexArg: {
              requiredField: true,
              unknownField: "value"
            })
          }
        }
      """, [
        bad_value_error(
          "complexArg",
          "ComplexInput",
          "{requiredField: true, unknownField: \"value\"}",
          4,
          41
        ),
      ]
    end

  end

  describe "Directive arguments" do

    it "with directives of valid types" do
      assert_passes_rule ArgumentsOfCorrectType, """
        {
          dog @include(if: true) {
            name
          }
          human @skip(if: false) {
            name
          }
        }
      """
    end

    it "with directive with incorrect types" do
      assert_fails_rule ArgumentsOfCorrectType, """
        {
          dog @include(if: "yes") {
            name @skip(if: ENUM)
          }
        }
      """, [
        bad_value_error("if", "Boolean!", "\"yes\"", 3, 28),
        bad_value_error("if", "Boolean!", "ENUM", 4, 28),
      ]
    end

  end

end
