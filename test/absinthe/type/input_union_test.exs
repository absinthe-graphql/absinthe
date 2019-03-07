defmodule Absinthe.Type.InputUnionTest do
  use Absinthe.Case, async: true

  alias Absinthe.Type

  defmodule TestSchema do
    use Absinthe.Schema

    query do
      # Query type must exist
    end

    input_object :person do
      description "A person"

      field :name, :string
      field :age, :integer
    end

    input_object :business do
      description "A business"

      field :name, :string
      field :employee_count, :integer
    end

    input_union :search_query do
      description "A search query"

      types [:person, :business]
    end

    input_object :foo do
      field :name, :string
    end

    input_union :other_query do
      types [:foo]
    end
  end

  describe "input union" do
    test "can be defined" do
      obj = TestSchema.__absinthe_type__(:search_query)

      assert %Absinthe.Type.InputUnion{
               name: "SearchQuery",
               description: "A search query",
               types: [:person, :business]
             } = obj
    end
  end
end
