defmodule Absinthe.Phase.Validation.KnownDirectivesTest do
  use Absinthe.Case, async: true

  @rule Absinthe.Phase.Validation.KnownDirectives

  use Support.Harness.Validation
  alias Absinthe.{Blueprint}

  def unknown_directive(name, line) do
    bad_value(
      Blueprint.Directive,
      "Unknown directive.",
      line,
      name: name
    )
  end

  def misplaced_directive(name, placement, line) do
    bad_value(
      Blueprint.Directive,
      "May not be used on #{placement}.",
      line,
      name: name
    )
  end

  describe "Validate: Known directives" do

    it "with no directives" do
      assert_passes_rule(@rule,
        """
        query Foo {
          name
          ...Frag
        }

        fragment Frag on Dog {
          name
        }
        """,
        %{}
      )
    end

    it "with known directives" do
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

    it "with unknown directive" do
      assert_fails_rule(@rule,
        """
        {
          dog @unknown(directive: "value") {
            name
          }
        }
        """,
        %{},
        [
          unknown_directive("unknown", 2)
        ]
      )
    end

    it "with many unknown directives" do
      assert_fails_rule(@rule,
        """
        {
          dog @unknown(directive: "value") {
            name
          }
          human @unknown(directive: "value") {
            name
            pets @unknown(directive: "value") {
              name
            }
          }
        }
        """,
        %{},
        [
          unknown_directive("unknown", 2),
          unknown_directive("unknown", 5),
          unknown_directive("unknown", 7)
        ]
      )
    end

    it "with well placed directives" do
      assert_passes_rule(@rule,
        """
        query Foo @onQuery {
          name @include(if: true)
          ...Frag @include(if: true)
          skippedField @skip(if: true)
          ...SkippedFrag @skip(if: true)
        }

        mutation Bar @onMutation {
          someField
        }
        """,
        %{}
      )
    end

    it "with misplaced directives" do
      assert_fails_rule(@rule,
        """
        query Foo @include(if: true) {
          name @onQuery
          ...Frag @onQuery
        }

        mutation Bar @onQuery {
          someField
        }
        """,
        %{},
        [
          misplaced_directive("include", "QUERY", 1),
          misplaced_directive("onQuery", "FIELD", 2),
          misplaced_directive("onQuery", "FRAGMENT_SPREAD", 3),
          misplaced_directive("onQuery", "MUTATION", 6)
        ]
      )
    end

    describe "within schema language" do

      it "with well placed directives" do
        assert_passes_rule(@rule,
          """
          type MyObj implements MyInterface @onObject {
            myField(myArg: Int @onArgumentDefinition): String @onFieldDefinition
          }

          scalar MyScalar @onScalar

          interface MyInterface @onInterface {
            myField(myArg: Int @onArgumentDefinition): String @onFieldDefinition
          }

          union MyUnion @onUnion = MyObj | Other

          enum MyEnum @onEnum {
            MY_VALUE @onEnumValue
          }

          input MyInput @onInputObject {
            myField: Int @onInputFieldDefinition
          }

          schema @onSchema {
            query: MyQuery
          }
          """,
          :schema
        )
      end

      it "with misplaced directives" do
        assert_fails_rule(@rule,
          """
          type MyObj implements MyInterface @onInterface {
            myField(myArg: Int @onInputFieldDefinition): String @onInputFieldDefinition
          }

          scalar MyScalar @onEnum

          interface MyInterface @onObject {
            myField(myArg: Int @onInputFieldDefinition): String @onInputFieldDefinition
          }

          union MyUnion @onEnumValue = MyObj | Other

          enum MyEnum @onScalar {
            MY_VALUE @onUnion
          }

          input MyInput @onEnum {
            myField: Int @onArgumentDefinition
          }

          schema @onObject {
            query: MyQuery
          }
          """,
          :schema,
          [
            misplaced_directive("onInterface", "OBJECT", 1),
            misplaced_directive("onInputFieldDefinition", "ARGUMENT_DEFINITION", 2),
            misplaced_directive("onInputFieldDefinition", "FIELD_DEFINITION", 2),
            misplaced_directive("onEnum", "SCALAR", 5),
            misplaced_directive("onObject", "INTERFACE", 7),
            misplaced_directive("onInputFieldDefinition", "ARGUMENT_DEFINITION", 8),
            misplaced_directive("onInputFieldDefinition", "FIELD_DEFINITION", 8),
            misplaced_directive("onEnumValue", "UNION", 11),
            misplaced_directive("onScalar", "ENUM", 13),
            misplaced_directive("onUnion", "ENUM_VALUE", 14),
            misplaced_directive("onEnum", "INPUT_OBJECT", 17),
            misplaced_directive("onArgumentDefinition", "INPUT_FIELD_DEFINITION", 18),
            misplaced_directive("onObject", "SCHEMA", 21),
          ]
        )
      end

    end

  end
end
