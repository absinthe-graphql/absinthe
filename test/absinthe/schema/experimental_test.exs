defmodule Absinthe.Schema.ExperimentalTest do
  use Absinthe.Case

  @moduletag :experimental

  defmodule Schema do
    use Absinthe.Schema.Experimental

    query do
      field :user, :user do
        resolve fn _, _ ->
          {:ok, %{first_name: "Bruce", last_name: "Williams"}}
        end
      end
    end

    object :user do
      field :full_name, :string do
        resolve fn user, _, _ ->
          {:ok, "#{user.first_name} #{user.last_name}"}
        end
      end
    end
  end

  describe "__absinthe_blueprint__/0" do
    test "returns the blueprint" do
      assert 2 ==
               length(
                 Schema.__absinthe_blueprint__().schema_definitions |> List.first()
                 |> Map.get(:types)
               )
    end
  end

  describe "type lookup" do
    test "it works on objects" do
      assert %Absinthe.Type.Object{} = type = Absinthe.Schema.lookup_type(Schema, :user)
    end
  end

  test "simple" do
    query = """
    { user { fullName }}
    """
    assert :ok = Absinthe.run(query, Schema)
  end
end
