defmodule Absinthe.Phase.Document.Validation.ArgumentsOfCorrectTypeTest do
  use Absinthe.Case, async: true

  @rule Absinthe.Phase.Document.Validation.ArgumentsOfCorrectType

  import Support.Harness.Validation
  alias Absinthe.{Blueprint, Phase}

  @spec bad_value(String.t, String.t, any, nil | integer) :: Support.Harness.Validation.error_checker_t
  defp bad_value(arg_name, type_name, value, line) do
    bad_value(arg_name, type_name, value, line, [~s(Expected type "#{type_name}", found #{value})])
  end

  @spec bad_value(String.t, String.t, any, nil | integer, [String.t]) :: Support.Harness.Validation.error_checker_t
  defp bad_value(arg_name, _type_name, _value, line, errors) do
    fn
      pairs ->
        assert !Enum.empty?(pairs), "No errors were found"
        Enum.each(errors, fn
          message ->
            error_matched = Enum.any?(pairs, fn
              {%Blueprint.Input.Argument{name: ^arg_name, flags: flags}, %Phase.Error{phase: @rule, message: ^message, locations: [%{line: ^line}]}} ->
                Enum.member?(flags, :invalid)
              _ ->
                false
            end)
            assert error_matched, "Could not find error:\n  ---\n  " <> message <> "\n  ---"
        end)
    end
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
        bad_value("stringArg", "String", "1", 3)
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
        bad_value("stringArg", "String", "1.0", 3)
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
        bad_value("stringArg", "String", "true", 3)
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
        bad_value("stringArg", "String", "BAR", 3)
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
        bad_value("intArg", "Int", ~s("3"), 3)
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
        bad_value("intArg", "Int", "829384293849283498239482938", 3)
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
        bad_value("intArg", "Int", "FOO", 3)
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
        bad_value("intArg", "Int", "3.0", 3)
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
        bad_value("intArg", "Int", "3.333", 3)
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
        bad_value("floatArg", "Float", ~s("3.333"), 3)
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
        bad_value("floatArg", "Float", "true", 3)
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
        bad_value("floatArg", "Float", "FOO", 3)
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
        bad_value("booleanArg", "Boolean", "2", 3)
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
        bad_value("booleanArg", "Boolean", "1.0", 3)
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
        bad_value("booleanArg", "Boolean", ~s("true"), 3)
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
        bad_value("booleanArg", "Boolean", "TRUE", 3)
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
        bad_value("idArg", "ID", "1.0", 3)
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
        bad_value("idArg", "ID", "true", 3)
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
        bad_value("idArg", "ID", "SOMETHING", 3)
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
        bad_value("dogCommand", "DogCommand", "2", 3)
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
        bad_value("dogCommand", "DogCommand", "1.0", 3)
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
        bad_value("dogCommand", "DogCommand", ~s("SIT"), 3)
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
        bad_value("dogCommand", "DogCommand", "true", 3)
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
        bad_value("dogCommand", "DogCommand", "JUGGLE", 3)
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
        bad_value("dogCommand", "DogCommand", "sit", 3)
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
        bad_value(
          "stringListArg", "[String]", ~s(["one", 2]), 3,
          [~s(In element #1: Expected type "String", found 2.)]
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
        bad_value("stringListArg", "[String]", "1", 3)
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
          bad_value("req2", "Int!", ~s("two"), 3),
          bad_value("req1", "Int!", ~s("one"), 3)
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
        bad_value("req1", "Int!", ~s("one"), 3)
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
        bad_value(
          "complexArg", "ComplexInput", "{intField: 4}", 3,
          [
            ~s(In field "requiredField": Expected "Boolean!", found null.)
          ]
        )
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
        bad_value(
          "complexArg",
          "ComplexInput",
          ~s({stringListField: ["one", 2], requiredField: true}),
          3,
          [
            ~s(In field "stringListField": In element #1: Expected type "String", found 2.)
          ]
        )
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
        bad_value(
          "complexArg",
          "ComplexInput",
          ~s({requiredField: true, unknownField: "value"}),
          3,
          [
            ~s(In field "unknownField": Unknown field.)
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
          bad_value("if", "Boolean!", ~s("yes"), 2),
          bad_value("if", "Boolean!", "ENUM", 3)
        ]
      )
    end

  end

end
