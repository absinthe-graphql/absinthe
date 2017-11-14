defmodule Absinthe.Middleware.OrderedAliasTest do
  use Absinthe.Case, async: false, ordered: true
  use OrdMap

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
    expected_data = o%{
      "userId" => o(%{"id" => 42}),
      "userName" => o%{"name" => "foobar"}
    }

    assert {:ok, %{data: data}} = Absinthe.run(doc, Schema)
    assert expected_data == data
  end

end
