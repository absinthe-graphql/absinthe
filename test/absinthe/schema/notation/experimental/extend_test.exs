defmodule Absinthe.Schema.Notation.Experimental.ExtendTest do
  use Absinthe.Case
  import ExperimentalNotationHelpers

  @moduletag :experimental

  defmodule Definition do
    use Absinthe.Schema.Notation

    object :my_object do
      field :foo, :string
    end

    extend :my_object do
      field :bar, :string
    end
  end

  describe "extend" do
    test "my_object" do
      assert %{name: "MyObject", identifier: :my_object, fields: fields} =
               lookup_type(Definition, :my_object)

      field_identifiers = Enum.map(fields, & &1.identifier)
      assert :foo in field_identifiers
      assert :bar in field_identifiers

      %{schema_definitions: [%{type_definitions: type_definitions}]} =
        Definition.__absinthe_blueprint__()

      assert length(type_definitions) == 1
    end
  end
end
