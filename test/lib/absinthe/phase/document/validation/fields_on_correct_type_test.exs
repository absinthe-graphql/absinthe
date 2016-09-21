defmodule Absinthe.Phase.Document.Validation.FieldsOnCorrectTypeTest do
  use Absinthe.Case, async: true

  @rule Absinthe.Phase.Document.Validation.FieldsOnCorrectType

  use Support.Harness.Validation
  alias Absinthe.Blueprint

  defp undefined_field(name, type_name, type_suggestions, field_suggestions, line) do
    bad_value(
      Blueprint.Document.Field,
      @rule.error_message(name, type_name, type_suggestions, field_suggestions),
      line,
      name: name
    )
  end

  describe "Validate: Fields on correct type" do

    it "Object field selection" do
      assert_passes_rule(@rule,
        """
        fragment objectFieldSelection on Dog {
          __typename
          name
        }
        """,
        []
      )
    end

    it "Aliased object field selection" do
      assert_passes_rule(@rule,
        """
        fragment aliasedObjectFieldSelection on Dog {
          tn : __typename
          otherName : name
        }
        """,
        []
      )
    end

    it "Interface field selection" do
      assert_passes_rule(@rule,
        """
        fragment interfaceFieldSelection on Pet {
          __typename
          name
        }
        """,
        []
      )
    end

    it "Aliased interface field selection" do
      assert_passes_rule(@rule,
        """
        fragment interfaceFieldSelection on Pet {
          otherName : name
        }
        """,
        []
      )
    end

    it "Lying alias selection" do
      assert_passes_rule(@rule,
        """
        fragment lyingAliasSelection on Dog {
          name : nickname
        }
        """,
        []
      )
    end

    it "Ignores fields on unknown type" do
      assert_passes_rule(@rule,
        """
        fragment unknownSelection on UnknownType {
          unknownField
        }
        """,
        []
      )
    end

    it "reports errors when type is known again" do
      assert_fails_rule(@rule,
        """
        fragment typeKnownAgain on Pet {
          unknown_pet_field {
            ... on Cat {
              unknown_cat_field
            }
          }
        }
        """,
        [],
        [
          undefined_field("unknown_pet_field", "Pet", [], [], 2),
          undefined_field("unknown_cat_field", "Cat", [], [], 4)
        ]
      )
    end

    it "Field not defined on fragment" do
      assert_fails_rule(@rule,
        """
        fragment fieldNotDefined on Dog {
          meowVolume
        }
        """,
        [],
        undefined_field("meowVolume", "Dog", [], ["barkVolume"], 2)
      )
    end

    it "Ignores deeply unknown field" do
      assert_fails_rule(@rule,
        """
        fragment deepFieldNotDefined on Dog {
          unknown_field {
            deeper_unknown_field
          }
        }
        """,
        [],
        undefined_field("unknown_field", "Dog", [], [], 2)
      )
    end

    it "Sub-field not defined" do
      assert_fails_rule(@rule,
        """
        fragment subFieldNotDefined on Human {
          pets {
            unknown_field
          }
        }
        """,
        [],
        undefined_field("unknown_field", "Pet", [], [], 3)
      )
    end

    it "Field not defined on inline fragment" do
      assert_fails_rule(@rule,
        """
        fragment fieldNotDefined on Pet {
          ... on Dog {
            meowVolume
          }
        }
        """,
        [],
        undefined_field("meowVolume", "Dog", [], ["barkVolume"], 3)
      )
    end

    it "Aliased field target not defined" do
      assert_fails_rule(@rule,
        """
        fragment aliasedFieldTargetNotDefined on Dog {
          volume : mooVolume
        }
        """,
        [],
        undefined_field("mooVolume", "Dog", [], ["barkVolume"], 2)
      )
    end

    it "Aliased lying field target not defined" do
      assert_fails_rule(@rule,
        """
        fragment aliasedLyingFieldTargetNotDefined on Dog {
          barkVolume : kawVolume
        }
        """,
        [],
        undefined_field("kawVolume", "Dog", [], ["barkVolume"], 2)
      )
    end

    it "Not defined on interface" do
      assert_fails_rule(@rule,
        """
        fragment notDefinedOnInterface on Pet {
          tailLength
        }
        """,
        [],
        undefined_field("tailLength", "Pet", [], [], 2)
      )
    end

    it "Defined on implementors but not on interface" do
      assert_fails_rule(@rule,
        """
        fragment definedOnImplementorsButNotInterface on Pet {
          nickname
        }
        """,
        [],
        undefined_field("nickname", "Pet", ["Dog", "Cat"], ["name"], 2)
      )
    end

    it "Meta field selection on union" do
      assert_passes_rule(@rule,
        """
        fragment directFieldSelectionOnUnion on CatOrDog {
          __typename
        }
        """,
        []
      )
    end

    it "Direct field selection on union" do
      assert_fails_rule(@rule,
        """
        fragment directFieldSelectionOnUnion on CatOrDog {
          directField
        }
        """,
        [],
        undefined_field("directField", "CatOrDog", [], [], 2)
      )
    end

    it "Defined on implementors queried on union" do
      assert_fails_rule(@rule,
        """
        fragment definedOnImplementorsQueriedOnUnion on CatOrDog {
          name
        }
        """,
        [],
        undefined_field("name", "CatOrDog", ["Being", "Pet", "Canine", "Dog", "Cat"], [], 2)
      )
    end

    it "valid field in inline fragment" do
      assert_passes_rule(@rule,
        """
        fragment objectFieldSelection on Pet {
          ... on Dog {
            name
          }
          ... {
            name
          }
        }
        """,
        []
      )
    end

    describe "Fields on correct type error message" do

      it "Works with no suggestions" do
        assert ~s(Cannot query field "f" on type "T".) == @rule.error_message("f", "T", [], [])
      end

      it "Works with no small numbers of type suggestions" do
        assert ~s(Cannot query field "f" on type "T". Did you mean to use an inline fragment on "A" or "B"?) == @rule.error_message("f", "T", [ "A", "B" ], [])
      end

      it "Works with no small numbers of field suggestions" do
        assert ~s(Cannot query field "f" on type "T". Did you mean "z" or "y"?) == @rule.error_message("f", "T", [], [ "z", "y" ])
      end

      it "Only shows one set of suggestions at a time, preferring types" do
        assert ~s(Cannot query field "f" on type "T". Did you mean to use an inline fragment on "A" or "B"?) == @rule.error_message("f", "T", [ "A", "B" ], [ "z", "y" ])
      end

      it "Limits lots of type suggestions" do
        assert ~s(Cannot query field "f" on type "T". Did you mean to use an inline fragment on "A", "B", "C", "D", or "E"?) == @rule.error_message("f", "T", [ "A", "B", "C", "D", "E", "F" ], [])
      end

      it "Limits lots of field suggestions" do
        assert ~s(Cannot query field "f" on type "T". Did you mean "z", "y", "x", "w", or "v"?) == @rule.error_message("f", "T", [], [ "z", "y", "x", "w", "v", "u" ])
      end

    end
  end

end
