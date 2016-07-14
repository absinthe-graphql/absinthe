defmodule Absinthe.Phase.Document.Validation.NoFragmentCyclesTest do
  use Absinthe.Case, async: true

  alias Absinthe.{Phase, Pipeline}

  describe ".run" do

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


    it "should return an error if the named fragment tries to use itself" do

      {:error, blueprint} = """
      fragment nameFragment on Dog {
        name
        ...nameFragment
      }
      """
      |> run

      assert Enum.find(blueprint.fragments, fn
        %{name: "nameFragment", errors: [%{message: "forms a cycle with itself"}]} ->
          true
        _ ->
          false
     end)
    end

    it "should add errors to named fragments that form a cycle" do
      {:error, blueprint} = """
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

      quux_msg = "forms a cycle via: (`quux' => `foo' => `bar' => `baz' => `quux')"
      baz_msg = "forms a cycle via: (`baz' => `quux' => `foo' => `bar' => `baz')"

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
    {:ok, blueprint} = input
    |> Pipeline.run([
      Phase.Parse,
      Phase.Blueprint
    ])
    Phase.Document.Validation.NoFragmentCycles.run(blueprint, [])
  end

end
