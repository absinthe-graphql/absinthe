defmodule Absinthe.Phase.Document.Validation.ProvidedNonNullArgumentsTest do
  use Absinthe.Case, async: true

  @rule Absinthe.Phase.Document.Validation.ProvidedNonNullArguments

  use Support.Harness.Validation
  alias Absinthe.{Blueprint}

  defp message(type) do
    ~s(Expected type "#{type}", found null.)
  end

  describe "Validate: Provided required arguments" do

    it "ignores unknown arguments" do
      assert_passes_rule(@rule,
        """
        {
          dog {
            isHousetrained(unknownArgument: true)
          }
        }
        """,
        %{}
      )
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

      it "Missing one non-nullable argument" do
        assert_fails_rule(@rule,
          """
          {
            complicatedArgs {
              multipleReqs(req2: 2)
            }
          }
          """,
          %{},
          bad_value(Blueprint.Input.Argument, message("Int!"), 3, name: "req1")
        )
      end

      it "Missing multiple non-nullable arguments" do
        assert_fails_rule(@rule,
          """
          {
            complicatedArgs {
              multipleReqs
            }
          }
          """,
          %{},
          [
            bad_value(Blueprint.Input.Argument, message("Int!"), 3, name: "req1"),
            bad_value(Blueprint.Input.Argument, message("Int!"), 3, name: "req2")
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
          bad_value(Blueprint.Input.Argument, message("Int!"), 3, name: "req2")
        )
      end

    end

    describe "Directive arguments" do

      it "ignores unknown directives" do
        assert_passes_rule(@rule,
        """
          {
            dog @unknown
          }
          """,
        %{}
      )
      end

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

      @tag :focus
      it "with directive with missing types" do
        assert_fails_rule(@rule,
          """
          {
            dog @include {
              name @skip
            }
          }
          """,
          %{},
          [
            bad_value(Blueprint.Input.Argument, message("Boolean!"), 2, name: "if"),
            bad_value(Blueprint.Input.Argument, message("Boolean!"), 3, name: "if"),
          ]
        )
      end

    end

  end

end
