defmodule Absinthe.Phase.Document.Arguments.DataTest do
  use Absinthe.Case, async: true

  @moduletag :obselete

  alias Absinthe.{Blueprint, Phase}

  import BlueprintHelpers

  defmodule Schema do
    use Absinthe.Schema

    mutation do
      field :profile, :profile do
        arg :input, non_null(:input_profile)
      end
    end

    query do
      field :profile, :profile do
        arg :id, non_null(:id)
      end
      field :profiles, list_of(:profile) do
        arg :ids, non_null(list_of(:id))
      end
    end

    input_object :input_profile do
      field :name, non_null(:string)
      field :age, :integer
    end

    object :profile do
      field :id, non_null(:id)
      field :name, non_null(:string)
      field :age, :integer
    end

  end

  use Harness.Document.Phase, phase: Phase.Document.Arguments.Data, schema: Schema

  describe "with variables" do

    @query """
    mutation CreateProfileWithVariable($input: InputProfile!) {
      profile(input: $input) {
        id name age
      }
    }
    query Profile($id: ID!, $ids: [ID]!) {
      profile(id: $id) {
        name
      }
      other: profile(id: $bad) {
        name
      }
      profiles(ids: $ids) {
        name
      }
    }
    """

    it "sets data_value using valid, provided data" do
      {:ok, result, _} = run_phase(@query, variables: %{"input" => %{"name" => "Bruce", "age" => 36}})
      arg = named(result, Blueprint.Input.Argument, "input")
      assert %{name: "Bruce", age: 36} == arg.data_value
    end

    it "does not set data_value if additional data is provided that does not fit into the schema" do
      {:ok, result, _} = run_phase(@query, variables: %{"input" => %{"name" => "Bruce", "age" => 36, "other" => 123}})
      arg = named(result, Blueprint.Input.Argument, "input")
      assert nil == arg.data_value
    end

    it "sets data_value to a scalar value, given one" do
      {:ok, result, _} = run_phase(@query, variables: %{"id" => "234"})
      arg = named(result, Blueprint.Input.Argument, "id")
      assert "234" == arg.data_value
    end

    it "doesn't set data_value for an un-declared variable" do
      {:ok, result, _} = run_phase(@query, variables: %{"bad" => "234"})
      other = named(result, Blueprint.Document.Field, "other")
      arg = named(other, Blueprint.Input.Argument, "id")
      assert nil == arg.data_value
    end

    it "sets data_value that is a list" do
      {:ok, result, _} = run_phase(@query, variables: %{"ids" => ~w(2 3 4)})
      arg = named(result, Blueprint.Input.Argument, "ids")
      assert ~w(2 3 4) == arg.data_value
    end

  end

  describe "using literals" do

    @query """
    mutation CreateProfileWithVariable {
      profile1: profile(input: {name: "Bruce", age: 36}) {
        id name age
      }
      profile2: profile(input: {name: "Brian", age: 28, location: "PDX"}) {
        id name age
      }
      profile3: profile(input: {name: "Melissa", age: []}) {
        id name age
      }
    }
    query Profile {
      profile(id: 234) {
        name
      }
    }
    """

    it "sets data_value using valid, provided data" do
      {:ok, result, _} = run_phase(@query, variables: %{})
      op = named(result, Blueprint.Document.Operation, "CreateProfileWithVariable")
      profile1 = named(op, Blueprint.Document.Field, "profile1")
      arg = named(profile1, Blueprint.Input.Argument, "input")
      assert %{name: "Bruce", age: 36} == arg.data_value
    end

    it "does not set data_value when provided data does not fit schema" do
      {:ok, result, _} = run_phase(@query, variables: %{"input" => %{"name" => "Bruce", "age" => 36, "other" => 123}})
      op = named(result, Blueprint.Document.Operation, "CreateProfileWithVariable")
      profile2 = named(op, Blueprint.Document.Field, "profile2")
      arg = named(profile2, Blueprint.Input.Argument, "input")
      assert nil == arg.data_value
    end

    it "sets data_value to a scalar value, given one" do
      {:ok, result, _} = run_phase(@query, variables: %{})
      op = named(result, Blueprint.Document.Operation, "Profile")
      arg = named(op, Blueprint.Input.Argument, "id")
      assert "234" == arg.data_value
    end

  end


end
