defmodule Absinthe.Validation.PreventCircularFragmentsTest do
  use ExSpec, async: true

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

      Fragment `nameFragment' forms a cycle via: (`nameFragment' => `nameFragment')
      """

      assert {:error, errors, _} = Validation.run(doc)
      assert [error] == errors
    end

    it "should error if named fragments form a cycle" do
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

      error = """
      Fragment Cycle Error

      Fragment `barkVolumeFragment' forms a cycle via: (`barkVolumeFragment' => `nameFragment' => `barkVolumeFragment')
      """

      assert {:error, errors, _} = Validation.run(doc)
      assert [error] == errors
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

      error = """
      Fragment Cycle Error

      Fragment `barkVolumeFragment' forms a cycle via: (`barkVolumeFragment' => `nameFragment' => `barkVolumeFragment')
      """

      assert {:ok, %{errors: errors}} = Absinthe.run(doc, Things)
      assert [error] == errors
    end
  end
end
