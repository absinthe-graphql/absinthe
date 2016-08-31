defmodule Absinthe.Phase.Document.Validation.ArgumentsOfCorrectTypeTest do
  use Absinthe.Case, async: true

  @rule Absinthe.Phase.Document.Validation.ArgumentsOfCorrectType

  use Support.Harness.Validation
  alias Absinthe.{Blueprint}

  defp expected_type_message(type_name, value) do
    ~s(Expected type "#{type_name}", found #{value})
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
        %{}
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
        %{}
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
        %{}
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
        %{}
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
        %{}
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
        %{}
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
        %{}
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
        %{}
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
        %{},
        bad_value(Blueprint.Input.Argument, expected_type_message("String", "1"), 3)
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
        %{},
        bad_value(Blueprint.Input.Argument, expected_type_message("String", "1.0"), 3, name: "stringArg")
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
        %{},
        bad_value(Blueprint.Input.Argument, expected_type_message("String", "true"), 3, name: "stringArg")
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
        %{},
        bad_value(Blueprint.Input.Argument, expected_type_message("String", "BAR"), 3, name: "stringArg")
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
        %{},
        bad_value(Blueprint.Input.Argument, expected_type_message("Int", ~s("3")), 3, name: "intArg")
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
        %{},
        bad_value(Blueprint.Input.Argument, expected_type_message("Int", "829384293849283498239482938"), 3, name: "intArg")
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
        %{},
        bad_value(Blueprint.Input.Argument, expected_type_message("Int", "FOO"), 3, name: "intArg")
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
        %{},
        bad_value(Blueprint.Input.Argument, expected_type_message("Int", "3.0"), 3, name: "intArg")
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
        %{},
        bad_value(Blueprint.Input.Argument, expected_type_message("Int", "3.333"), 3, name: "intArg")
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
        %{},
        bad_value(Blueprint.Input.Argument, expected_type_message("Float", ~s("3.333")), 3, name: "floatArg")
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
        %{},
        bad_value(Blueprint.Input.Argument, expected_type_message("Float", "true"), 3, name: "floatArg")
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
        %{},
        bad_value(Blueprint.Input.Argument, expected_type_message("Float", "FOO"), 3, name: "floatArg")
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
        %{},
        bad_value(Blueprint.Input.Argument, expected_type_message("Boolean", "2"), 3, name: "booleanArg")
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
        %{},
        bad_value(Blueprint.Input.Argument, expected_type_message("Boolean", "1.0"), 3, name: "booleanArg")
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
        %{},
        bad_value(Blueprint.Input.Argument, expected_type_message("Boolean", ~s("true")), 3, name: "booleanArg")
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
        %{},
        bad_value(Blueprint.Input.Argument, expected_type_message("Boolean", "TRUE"), 3, name: "booleanArg")
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
        %{},
        bad_value(Blueprint.Input.Argument, expected_type_message("ID", "1.0"), 3, name: "idArg")
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
        %{},
        bad_value(Blueprint.Input.Argument, expected_type_message("ID", "true"), 3, name: "idArg")
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
        %{},
        bad_value(Blueprint.Input.Argument, expected_type_message("ID", "SOMETHING"), 3, name: "idArg")
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
        %{},
        bad_value(Blueprint.Input.Argument, expected_type_message("DogCommand", "2"), 3, name: "dogCommand")
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
        %{},
        bad_value(Blueprint.Input.Argument, expected_type_message("DogCommand", "1.0"), 3, name: "dogCommand")
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
        %{},
        bad_value(Blueprint.Input.Argument, expected_type_message("DogCommand", ~s("SIT")), 3, name: "dogCommand")
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
        %{},
        bad_value(Blueprint.Input.Argument, expected_type_message("DogCommand", "true"), 3, name: "dogCommand")
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
        %{},
        bad_value(Blueprint.Input.Argument, expected_type_message("DogCommand", "JUGGLE"), 3, name: "dogCommand")
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
        %{},
        bad_value(Blueprint.Input.Argument, expected_type_message("DogCommand", "sit"), 3, name: "dogCommand")
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
        %{}
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
        %{}
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
        %{}
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
        %{},
        [
          bad_value(Blueprint.Input.Argument, expected_type_message("[String]", ~s(["one", 2])), 3, name: "stringListArg"),
          bad_value(Blueprint.Input.Integer, expected_type_message("String", "2"), 3)
        ]
      )
    end

    @tag :focus
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
        [
          bad_value(Blueprint.Input.Argument, expected_type_message("[String]", "1"), 3, name: "stringListArg"),
          bad_value(Blueprint.Input.Integer, expected_type_message("String", "1"), 3)
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
        %{}
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
        %{}
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
        %{}
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
        %{}
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
        %{}
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
        %{}
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
        %{}
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
        %{}
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
        %{}
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
        %{}
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
        %{},
        [
          bad_value(Blueprint.Input.Argument, expected_type_message("Int!", ~s("two")), 3, name: "req2"),
          bad_value(Blueprint.Input.Argument, expected_type_message("Int!", ~s("one")), 3, name: "req1")
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
        %{},
        bad_value(Blueprint.Input.Argument, expected_type_message("Int!", ~s("one")), 3, name: "req1")
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
        %{}
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
        %{}
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
        %{}
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
        %{}
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
        %{}
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
        %{}
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
        %{},
        [
          bad_value(Blueprint.Input.Argument, expected_type_message("ComplexInput", "{intField: 4}"), 3, name: "complexArg"),
          bad_value(Blueprint.Input.Field, expected_type_message("Boolean!", "null"), 3, name: "requiredField")
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
        %{},
        [
          bad_value(Blueprint.Input.Argument, expected_type_message("ComplexInput", ~s({stringListField: ["one", 2], requiredField: true})), 3, name: "complexArg"),
          bad_value(Blueprint.Input.Integer, expected_type_message("String", "2"), 4)
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
        %{},
        [
          bad_value(Blueprint.Input.Argument, expected_type_message("ComplexInput", ~s({requiredField: true, unknownField: "value"})), 3, name: "complexArg"),
          bad_value(Blueprint.Input.Field, "Unknown field.", 5, name: "unknownField")
        ]
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
        %{}
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
        %{},
        [
          bad_value(Blueprint.Input.Argument, expected_type_message("Boolean!", ~s("yes")), 2, name: "if"),
          bad_value(Blueprint.Input.Argument, expected_type_message("Boolean!", "ENUM"), 3, name: "if")
        ]
      )
    end

  end

end
