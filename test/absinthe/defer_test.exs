defmodule Absinthe.DeferTest do
  use ExUnit.Case, async: false

  defmodule Schema do
    use Absinthe.Schema

    object :user do
      field :id, :id, resolve: &deferrable_resolver/3
      field :name, :string, resolve: &deferrable_resolver/3
      field :friends, list_of(:user), resolve: &friends_resolver/3
      field :address, :address, resolve: &address_resolver/3
    end

    object :address do
      field :street, :string
      field :town, :string
    end

    query do
      field :user, :user do
        resolve fn _, _, _ -> {:ok, %{name: "user"}} end
      end
    end

    defp deferrable_resolver(%{name: name}, _, %{definition: %{name: field}}) do
      {:ok, name <> "_" <> field}
    end

    defp friends_resolver(_, _, _) do
      {:ok, Enum.map(1..5, fn x -> %{name: to_string(x)} end)}
    end

    defp address_resolver(_, _, _) do
      {:ok, %{street: "Street", town: "Town"}}
    end
  end

  test "simple @defer directive" do
    doc = """
    { user { id @defer, name } }
    """

    {:more, %{data: data, continuation: cont}} = Absinthe.run(doc, Schema)

    assert data == %{"user" => %{"name" => "user_name"}}
    refute is_nil(cont)

    {:ok, %{data: data, path: path}} = Absinthe.continue(cont)

    assert data == "user_id"
    assert path == ["user", "id"]
  end

  test "top level @defer directive" do
    doc = """
    { user @defer { id, name } }
    """

    {:more, %{continuation: cont, data: data}} = Absinthe.run(doc, Schema)

    assert data == %{}
    refute is_nil(cont)

    {:ok, %{data: data, path: path}} = Absinthe.continue(cont)
    assert data == %{"name" => "user_name", "id" => "user_id"}
    assert path == ["user"]
  end

  test "list field @defer directive" do
    doc = """
    { user { friends @defer { name } } }
    """

    {:more, %{continuation: cont, data: data}} = Absinthe.run(doc, Schema)

    assert data == %{"user" => %{}}
    refute is_nil(cont)

    {:ok, %{data: data, path: path}} = Absinthe.continue(cont)

    assert data == Enum.map(1..5, fn x -> %{"name" => to_string(x) <> "_name"} end)
    assert path == ["user", "friends"]
  end

  test "list element @defer directive" do
    doc = """
    { user { friends { name @defer } } }
    """

    {:more, %{continuation: cont, data: data}} = Absinthe.run(doc, Schema)

    assert data == %{"user" => %{"friends" => List.duplicate(%{}, 5)}}
    refute is_nil(cont)

    cont =
      Enum.reduce(1..4, cont, fn n, c ->
        {:more, %{continuation: cont, data: data, path: path}} = Absinthe.continue(c)
        assert data == to_string(n) <> "_name"
        assert path == ["user", "friends", n - 1, "name"]
        refute is_nil(cont)
        cont
      end)

    {:ok, %{data: data, path: path}} = Absinthe.continue(cont)
    assert data == "5_name"
    assert path == ["user", "friends", 4, "name"]
  end

  test "nested defers are handled" do
    doc = """
    { user { friends @defer { name @defer } } }
    """

    {:more, %{continuation: cont, data: data}} = Absinthe.run(doc, Schema)

    assert data == %{"user" => %{}}
    refute is_nil(cont)

    {:more, %{continuation: cont, data: data, path: path}} = Absinthe.continue(cont)

    assert data == List.duplicate(%{}, 5)
    assert path == ["user", "friends"]

    cont =
      Enum.reduce(1..4, cont, fn n, c ->
        {:more, %{continuation: cont, data: data, path: path}} = Absinthe.continue(c)
        assert data == to_string(n) <> "_name"
        assert path == ["user", "friends", n - 1, "name"]
        refute is_nil(cont)
        cont
      end)

    {:ok, %{data: data,  path: path}} = Absinthe.continue(cont)
    assert data == "5_name"
    assert path == ["user", "friends", 4, "name"]
  end

  test "pre-resolved fields are correctly deferred" do
    doc = """
    { user { address { street, town @defer } } }
    """

    {:more, %{continuation: cont, data: data}} = Absinthe.run(doc, Schema)

    assert data == %{"user" => %{"address" => %{"street" => "Street"}}}
    refute is_nil(cont)

    {:ok, %{data: data,  path: path}} = Absinthe.continue(cont)

    assert data == "Town"
    assert path == ["user", "address", "town"]
  end

  test "deferred fragment" do
    doc = """
    {
      user @defer {
        ...addressPart
      }
    }

    fragment addressPart on User {
      address {
        street
      }
    }
    """

    {:more, %{continuation: cont, data: data}} = Absinthe.run(doc, Schema)

    assert data == %{}
    refute is_nil(cont)

    {:ok, %{data: data,  path: path}} = Absinthe.continue(cont)

    assert data == %{"address" => %{"street" => "Street"}}
    assert path == ["user"]
  end

  test "deferred fragment part" do
    doc = """
    {
      user {
        ...addressPart
      }
    }

    fragment addressPart on User {
      address {
        street @defer
      }
    }
    """

    {:more, %{continuation: cont, data: data}} = Absinthe.run(doc, Schema)

    assert data == %{"user" => %{"address" => %{}}}
    refute is_nil(cont)

    {:ok, %{data: data,  path: path}} = Absinthe.continue(cont)

    assert data == "Street"
    assert path == ["user", "address", "street"]
  end

  test "multiple defers" do
    doc = "{ user { id @defer, name @defer } }"

    {:more, %{continuation: cont, data: data}} = Absinthe.run(doc, Schema)

    refute is_nil(cont)
    assert data == %{"user" => %{}}

    {:more, %{continuation: cont, data: data, path: path}} = Absinthe.continue(cont)

    refute is_nil(cont)
    assert data == "user_id"
    assert path == ["user", "id"]

    {:ok, %{data: data,  path: path}} = Absinthe.continue(cont)
    assert data == "user_name"
    assert path == ["user", "name"]
  end
end
