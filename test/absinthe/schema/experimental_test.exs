defmodule Absinthe.Schema.ExperimentalTest do
  use Absinthe.Case

  @moduletag :experimental

  defmodule Foo do
    use Absinthe.Schema.Notation

    scalar :string do
      description """
      The `String` scalar type represents textual data, represented as UTF-8
      character sequences. The String type is most often used by GraphQL to
      represent free-form human-readable text.
      """

      serialize &to_string/1

      parse fn input, _ ->
        {:ok, to_string(input.value)}
      end
    end
  end

  defmodule Schema do
    use Absinthe.Schema
    import_types Foo

    query do
      field :user, :user do
        resolve fn _, _ ->
          {:ok, %{first_name: "Bruce", last_name: "Williams"}}
        end
      end

      field :hello, :string do
        arg :name, :string
        resolve fn a, b ->
          IO.puts "First input"
          IO.inspect a
          IO.puts "-------------------"
          {:ok, "hello"}
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
                 Schema.__absinthe_blueprint__().schema_definitions
                 |> List.first()
                 |> Map.get(:types)
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
    assert %{fields: %{user: field}} = type

    assert {:ok, %{data: %{"user" => %{"fullName" => "Bruce Williams"}}}} ==
             Absinthe.run(query, Schema)
  end

  @tag :simple
  test "simple input" do
    query = """
    { hello(name: "bob") }
    """

    assert {:ok, %{data: %{"hello" => "hello"}}} ==
             Absinthe.run(query, Schema)
  end
end
