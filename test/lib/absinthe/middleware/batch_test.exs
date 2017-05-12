defmodule Absinthe.Middleware.BatchTest do
  use Absinthe.Case, async: true

  defmodule Schema do
    use Absinthe.Schema

    @organizations 1..3 |> Map.new(&{&1, %{
      name: "Organization: ##{&1}"
    }})
    @users 1..3 |> Enum.map(&%{
      id: &1,
      name: "User: ##{&1}",
      organization_id: &1,
    })

    object :organization do
      field :id, :integer
      field :name, :string
    end

    object :user do
      field :name, :string
      field :organization, :organization do
        resolve fn user, _, _ ->
          batch({__MODULE__, :by_id}, user.organization_id, fn batch ->
            {:ok, Map.get(batch, user.organization_id)}
          end)
        end
      end
    end

    query do
      field :users, list_of(:user) do
        resolve fn _, _, _ -> {:ok, @users} end
      end
      field :organization, :organization do
        arg :id, non_null(:integer)
        resolve fn _, %{id: id}, _ ->
          batch({__MODULE__, :by_id}, id, fn batch ->
            {:ok, Map.get(batch, id)}
          end)
        end
      end
    end

    def by_id(_, ids) do
      Map.take(@organizations, ids)
    end
  end

  it "can resolve a field using the normal async helper" do
    doc = """
    {
      users {
        organization {
          name
        }
      }
    }
    """
    expected_data = %{"users" => [%{"organization" => %{"name" => "Organization: #1"}}, %{"organization" => %{"name" => "Organization: #2"}}, %{"organization" => %{"name" => "Organization: #3"}}]}

    assert {:ok, %{data: data}} = Absinthe.run(doc, Schema)
    assert expected_data == data
  end


  it "can resolve batched fields cross-query that have different data requirements" do
    doc = """
    {
      users {
        organization {
          name
        }
      }
      organization(id: 1) {
        id
      }
    }
    """
    expected_data = %{
      "users" => [
        %{"organization" => %{"name" => "Organization: #1"}},
        %{"organization" => %{"name" => "Organization: #2"}},
        %{"organization" => %{"name" => "Organization: #3"}},
      ],
      "organization" => %{"id" => 1},
    }

    assert {:ok, %{data: data}} = Absinthe.run(doc, Schema)
    assert expected_data == data
  end

end
