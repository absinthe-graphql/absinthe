defmodule Absinthe.Validation.PreventCircularFragmentsTest do
  use Absinthe.Case, async: true

  alias Absinthe.Validation

  # https://facebook.github.io/graphql/#sec-Fragment-spreads-must-not-form-cycles

  describe "PreventCircularFragments" do
    it "should error if the named fragment tries to use itself" do
      {:ok, doc} = """
      fragment nameFragment on Dog {
        name
        ...nameFragment
      }
      """
      |> Absinthe.parse

      error = """
      Fragment Cycle Error

      Fragment `nameFragment' forms a cycle via: (`nameFragment' => `nameFragment' => `nameFragment')
      """
      |> String.strip

      assert {:error, errors, _} = Validation.run(doc)
      assert [%{locations: [%{column: 0, line: 3}], message: error}] == errors
    end

    it "should error if named fragments form a cycle" do
      {:ok, doc} = """
      {
        dog {
          ...foo
        }
      }

      fragment foo on Dog {
        name
        ...bar
      }

      fragment bar on Dog {
        barkVolume
        ...baz
      }

      fragment baz on Dog {
        age
        ...bar
        ...qux
      }

      fragment qux on Dog {
        asdf
        ...foo
      }

      """
      |> Absinthe.parse

      msg1 = "Fragment Cycle Error\n\nFragment `qux' forms a cycle via: (`qux' => `foo' => `bar' => `baz' => `qux')"
      msg2 = "Fragment Cycle Error\n\nFragment `baz' forms a cycle via: (`baz' => `bar' => `baz')"

      assert {:error, errors, _} = Validation.run(doc)
      assert [
        %{locations: [%{column: 0, line: 25}], message: msg1},
        %{locations: [%{column: 0, line: 19}], message: msg2}
      ] == errors
    end

    it "should not execute" do
      {:ok, doc} = """
      {
        dog {
          ...nameFragment
        }
      }

      fragment nameFragment on Dog {
        name
        ...barkVolumeFragment
      }

      fragment barkVolumeFragment on Dog {
        barkVolume
        ...nameFragment
      }
      """
      |> Absinthe.parse

      msg = """
      Fragment Cycle Error

      Fragment `barkVolumeFragment' forms a cycle via: (`barkVolumeFragment' => `nameFragment' => `barkVolumeFragment')
      """
      |> String.strip

      assert {:ok, %{errors: errors}} = Absinthe.run(doc, Things)
      assert [%{locations: [%{column: 0, line: 14}], message: msg}] == errors
    end
  end
end
