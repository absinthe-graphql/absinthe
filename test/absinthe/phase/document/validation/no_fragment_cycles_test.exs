defmodule Absinthe.Phase.Document.Validation.NoFragmentCyclesTest do
  use Absinthe.Case, async: true

  alias Absinthe.{Phase, Pipeline}

  @phase Absinthe.Phase.Document.Validation.NoFragmentCycles

  describe ".run" do
    test "should return ok if a fragment does not cycle" do
      assert {:ok, _} =
               """
               fragment nameFragment on Dog {
                 name
               }
               fragment ageFragment on Dog {
                 age
               }
               """
               |> run
    end

    test "should sort fragments properly" do
      assert {:ok, %{fragments: fragments}} =
               """
               fragment nameFragment on Dog {
                 name
               }
               fragment ageFragment on Dog {
                 age
                 ...nameFragment
               }
               """
               |> run

      assert ["nameFragment", "ageFragment"] = fragments |> Enum.map(& &1.name)

      assert {:ok, %{fragments: fragments}} =
               """
               fragment ageFragment on Dog {
                 age
                 ...nameFragment
               }
               fragment nameFragment on Dog {
                 name
               }
               """
               |> run

      assert ["nameFragment", "ageFragment"] = fragments |> Enum.map(& &1.name)

      assert {:ok, %{fragments: fragments}} =
               """
               fragment FullType on __Type {
                 fields {
                   args {
                     ...InputValue
                   }
                 }
               }

               fragment InputValue on __InputValue {
                 type { name }
               }
               """
               |> run

      assert ["InputValue", "FullType"] = fragments |> Enum.map(& &1.name)
    end

    test "should return an error if the named fragment tries to use itself" do
      {:jump, blueprint, _} =
        """
        fragment nameFragment on Dog {
          name
          ...nameFragment
        }
        """
        |> run

      message = @phase.error_message("nameFragment", ["nameFragment"])

      assert Enum.find(blueprint.fragments, fn
               %{name: "nameFragment", errors: [%{message: ^message}]} ->
                 true

               _ ->
                 false
             end)
    end

    test "should add errors to named fragments that form a cycle" do
      {:jump, blueprint, _} =
        """
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

      quux_msg = @phase.error_message("quux", ~w(quux foo bar baz quux))
      baz_msg = @phase.error_message("baz", ~w(baz quux foo bar baz))

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
    {:ok, blueprint, _phases} =
      input
      |> Pipeline.run([
        Phase.Parse,
        Phase.Blueprint
      ])

    Phase.Document.Validation.NoFragmentCycles.run(blueprint, validation_result_phase: :stub)
  end
end
