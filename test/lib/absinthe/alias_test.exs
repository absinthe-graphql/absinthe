defmodule Absinthe.Middleware.AliasTest do
  use Absinthe.Case, async: true

  defmodule Schema do
    use Absinthe.Schema

    object :user do
      field :id, :integer
      field :name, :string
    end

    query do
      field :user, :user do
        resolve fn _, _, _ -> {:ok, %{id: 42, name: "foobar"}} end
      end
    end
  end

  it "can resolve different sub-fields on aliased fields" do
    doc = """
    {
      userId : user {
        id
      }
      userName : user {
        name
      }
    }
    """
    expected_data = %{
      "user_id" => %{"id" => 42},
      "userName" => %{"name" => "foobar"},
    }

    assert {:ok, %{data: data}} = Absinthe.run(doc, Schema)
    assert expected_data == data
  end

end
