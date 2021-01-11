defmodule Absinthe.Schema.ExperimentalTest do
  use Absinthe.Case, async: true

  @moduletag :experimental

  defmodule Schema do
    use Absinthe.Schema

    query do
      field :user, non_null(:user) do
        resolve fn _, _ ->
          {:ok, %{first_name: "Bruce", last_name: "Williams"}}
        end
      end

      field :hello, :string do
        arg :name, :string

        resolve fn %{name: name}, _ ->
          {:ok, "hello #{name}"}
        end
      end
    end

    @desc "user"
    object :user do
      @desc "their full name"
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
                 Schema.__absinthe_blueprint__().schema_definitions
                 |> List.first()
                 |> Map.fetch!(:type_definitions)
               )
    end
  end

  describe "type lookup" do
    test "it works on objects" do
      assert %Absinthe.Type.Object{} = type = Absinthe.Schema.lookup_type(Schema, :user)
      assert %{fields: %{full_name: field}} = type
      assert field.identifier == :full_name
      assert field.middleware != []
    end
  end

  test "simple" do
    query = """
    { user { fullName }}
    """

    assert %Absinthe.Type.Object{} = type = Absinthe.Schema.lookup_type(Schema, :query)
    assert %{fields: %{user: _field}} = type

    assert {:ok, %{data: %{"user" => %{"fullName" => "Bruce Williams"}}}} ==
             Absinthe.run(query, Schema)
  end

  test "simple input" do
    query = """
    { hello(name: "bob") }
    """

    assert {:ok, %{data: %{"hello" => "hello bob"}}} == Absinthe.run(query, Schema)
  end
end
