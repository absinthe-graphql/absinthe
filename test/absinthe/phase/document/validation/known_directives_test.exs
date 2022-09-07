defmodule Absinthe.Phase.Document.Validation.KnownDirectivesTest do
  @phase Absinthe.Phase.Document.Validation.KnownDirectives

  use Absinthe.ValidationPhaseCase,
    phase: @phase,
    async: true

  alias Absinthe.Blueprint

  def unknown_directive(name, line) do
    bad_value(
      Blueprint.Directive,
      "Unknown directive `#{name}`.",
      line,
      name: name
    )
  end

  def misplaced_directive(name, placement, line) do
    bad_value(
      Blueprint.Directive,
      "Directive `#{name}` may not be used on #{placement}.",
      line,
      name: name
    )
  end

  test "with no directives" do
    assert_passes_validation(
      """
      query Foo {
        name
        ...Frag
      }

      fragment Frag on Dog {
        name
      }
      """,
      []
    )
  end

  test "with known directives" do
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

  test "with unknown directive" do
    assert_fails_validation(
      """
      {
        dog @unknown(directive: "value") {
          name
        }
      }
      """,
      [],
      [
        unknown_directive("unknown", 2)
      ]
    )
  end

  test "with many unknown directives" do
    assert_fails_validation(
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
      [],
      [
        unknown_directive("unknown", 2),
        unknown_directive("unknown", 5),
        unknown_directive("unknown", 7)
      ]
    )
  end

  test "with well placed directives" do
    assert_passes_validation(
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
      []
    )
  end

  test "with misplaced directives" do
    assert_fails_validation(
      """
      query Foo @include(if: true) {
        name @onQuery
        ...Frag @onQuery
      }

      mutation Bar @onQuery {
        someField
      }
      """,
      [],
      [
        misplaced_directive("include", "QUERY", 1),
        misplaced_directive("onQuery", "FIELD", 2),
        misplaced_directive("onQuery", "FRAGMENT_SPREAD", 3),
        misplaced_directive("onQuery", "MUTATION", 6)
      ]
    )
  end

  @tag :pending
  describe "within schema language" do
    test "with well placed directives" do
      assert_passes_validation(
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

    @tag :pending
    test "with misplaced directives" do
      assert_fails_validation(
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
          misplaced_directive("onObject", "SCHEMA", 21)
        ]
      )
    end
  end
end
