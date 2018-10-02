defmodule Absinthe.Phase.Document.Arguments.NormalizeTest do
  use Absinthe.PhaseCase,
    phase: Absinthe.Phase.Document.Arguments.Normalize,
    schema: __MODULE__.Schema,
    async: true

  alias Absinthe.Blueprint

  defmodule Schema do
    use Absinthe.Schema

    query do
      field :foo, :foo do
        arg :id, non_null(:id)
      end

      field :profile, :user do
        arg :name, :string
        arg :age, :integer
      end

      field :things, :things
    end

    object :foo do
      field :bar, :string
    end

    object :user do
      field :id, non_null(:id)
      field :name, non_null(:string)
      field :age, :integer
    end

    object :things do
      field :items, list_of(:item) do
        arg :id, :id
      end
    end

    object :item do
      field :id, :id
    end
  end

  @query """
    query Foo($id: ID!) {
      foo(id: $id) {
        bar
      }
    }
    query Profile($age: Int = 36) {
      profile(name: "Bruce", age: $age) {
        id
      }
    }
  """

  @fragment_query """
    query Things($id: ID!) {
      things {
        ... thingsFooFragment
      }
    }
    fragment thingsFragment on Things {
      items(id: $id) {
        id
      }
    }
  """

  describe "when not providing a value for an optional variable with a default value" do
    test "uses the default value" do
      {:ok, result, _} = run_phase(@query, variables: %{}, operation_name: "Profile")
      op = result.operations |> Enum.find(&(&1.name == "Profile"))
      field = op.selections |> List.first()
      age_argument = field.arguments |> Enum.find(&(&1.name == "age"))

      assert %Blueprint.Input.Integer{
               value: 36,
               source_location: %Blueprint.SourceLocation{column: 29, line: 6}
             } == age_argument.input_value.normalized

      name_argument = field.arguments |> Enum.find(&(&1.name == "name"))

      assert %Blueprint.Input.String{
               value: "Bruce",
               source_location: %Blueprint.SourceLocation{column: 19, line: 7}
             } == name_argument.input_value.normalized
    end
  end

  describe "when providing a value for an optional variable with a default value" do
    test "uses the default value" do
      {:ok, result, _} = run_phase(@query, variables: %{"age" => 4}, operation_name: "Profile")
      op = result.operations |> Enum.find(&(&1.name == "Profile"))
      field = op.selections |> List.first()
      age_argument = field.arguments |> Enum.find(&(&1.name == "age"))
      assert %Blueprint.Input.Integer{value: 4} == age_argument.input_value.normalized
      name_argument = field.arguments |> Enum.find(&(&1.name == "name"))

      assert %Blueprint.Input.String{
               value: "Bruce",
               source_location: %Blueprint.SourceLocation{column: 19, line: 7}
             } == name_argument.input_value.normalized
    end
  end

  describe "when providing an input to a fragment" do
    test "normalizes the input" do
      {:ok, result, _} = run_phase(@fragment_query, variables: %{"id" => "foo"})
      frag = result.fragments |> Enum.find(&(&1.name == "thingsFragment"))
      field = frag.selections |> List.first()
      id_argument = field.arguments |> Enum.find(&(&1.name == "id"))
      assert %Blueprint.Input.String{value: "foo"} == id_argument.input_value.normalized
    end
  end
end
