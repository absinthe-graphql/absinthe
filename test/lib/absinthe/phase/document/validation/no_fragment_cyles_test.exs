defmodule Absinthe.Phase.Document.Validation.NoFragmentCyclesTest do
  use Absinthe.Case, async: true

  alias Absinthe.{Phase, Pipeline}

  describe ".run" do

    it "should error if the named fragment tries to use itself" do
      {:ok, blueprint} = """
      fragment nameFragment on Dog {
        name
        ...nameFragment
      }
      """
      |> run

      assert Enum.find(blueprint.fragments, fn
        %{name: "nameFragment", errors: [%{message: "forms a cycle via: (`nameFragment' => `nameFragment' => `nameFragment')", locations: [%{line: 3}]}]} ->
          true
        _ ->
          false
     end)
    end

    it "should add errors to named fragments that form a cycle" do
      {:ok, blueprint} = """
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
      baz_msg = "forms a cycle via: (`baz' => `bar' => `baz')"

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
    input
    |> Pipeline.run([
      Phase.Parse,
      Phase.Blueprint,
      Phase.Document.Validation.NoFragmentCycles,
    ])
  end

end
