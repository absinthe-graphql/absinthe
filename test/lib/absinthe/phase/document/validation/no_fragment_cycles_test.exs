defmodule Absinthe.Phase.Document.Validation.NoFragmentCyclesTest do
  use Absinthe.Case, async: true

  alias Absinthe.{Phase, Pipeline}

  @rule Absinthe.Phase.Document.Validation.NoFragmentCycles

  context ".run" do

    it "should return ok if a fragment does not cycle" do
      assert {:ok, _} = """
      fragment nameFragment on Dog {
        name
      }
      fragment ageFragment on Dog {
        age
      }
      """
      |> run
    end

    it "should sort fragments properly" do
      assert {:ok, %{fragments: fragments}} = """
      fragment nameFragment on Dog {
        name
      }
      fragment ageFragment on Dog {
        age
        ...nameFragment
      }
      """
      |> run

      assert ["nameFragment", "ageFragment"] = fragments |> Enum.map(&(&1.name))

      assert {:ok, %{fragments: fragments}} = """
      fragment nameFragment on Dog {
        name
        ...ageFragment
      }
      fragment ageFragment on Dog {
        age
      }
      """
      |> run

      assert ["ageFragment", "nameFragment"] == fragments |> Enum.map(&(&1.name))
    end

    it "should return an error if the named fragment tries to use itself" do

      {:jump, blueprint, _} = """
      fragment nameFragment on Dog {
        name
        ...nameFragment
      }
      """
      |> run

      message = @rule.error_message("nameFragment", ["nameFragment"])
      assert Enum.find(blueprint.fragments, fn
        %{name: "nameFragment", errors: [%{message: ^message}]} ->
          true
        _ ->
          false
     end)
    end

    it "should add errors to named fragments that form a cycle" do
      {:jump, blueprint, _} = """
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
        ...quux
      }

      fragment quux on Dog {
        asdf
        ...foo
      }

      """
      |> run

      quux_msg = @rule.error_message("quux", ~w(quux foo bar baz quux))
      baz_msg = @rule.error_message("baz", ~w(baz quux foo bar baz))

      assert Enum.find(blueprint.fragments, fn
        %{name: "baz", errors: [%{message: ^baz_msg}]} ->
          true
        _ ->
          false
      end)

      assert Enum.find(blueprint.fragments, fn
        %{name: "quux", errors: [%{message: ^quux_msg}]} ->
          true
        _ ->
          false
      end)
    end

  end

  def run(input) do
    {:ok, blueprint, _phases} = input
    |> Pipeline.run([
      Phase.Parse,
      Phase.Blueprint
    ])
    Phase.Document.Validation.NoFragmentCycles.run(blueprint, validation_result_phase: :stub)
  end

end
