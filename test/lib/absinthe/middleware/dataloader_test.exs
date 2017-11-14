defmodule Absinthe.Middleware.DataloaderTest do
  use Absinthe.Case, async: false, ordered: false

  defmodule Schema do
    use Absinthe.Schema

    import Absinthe.Resolution.Helpers

    @organizations 1..3 |> Map.new(&{&1, %{
      id: &1,
      name: "Organization: ##{&1}"
    }})
    @users 1..3 |> Enum.map(&%{
      id: &1,
      name: "User: ##{&1}",
      organization_id: &1,
    })

    defp batch_load({:organization, test_pid}, ids) do
      send test_pid, :loading
      Map.take(@organizations, ids)
    end

    def context(ctx) do
      source = Dataloader.KV.new(&batch_load/2)
      loader = Dataloader.add_source(Dataloader.new, :test, source)

      Map.merge(ctx, %{
        loader: loader,
        test_pid: self()
      })
    end

    def plugins do
      [Absinthe.Middleware.Dataloader] ++ Absinthe.Plugin.defaults()
    end

    object :organization do
      field :id, :integer
      field :name, :string
    end

    object :user do
      field :name, :string
      field :organization, :organization do
        resolve fn user, _, %{context: %{loader: loader, test_pid: test_pid}} ->
          loader
          |> Dataloader.load(:test, {:organization, test_pid}, user.organization_id)
          |> on_load(fn loader ->
            {:ok, Dataloader.get(loader, :test, {:organization, test_pid}, user.organization_id)}
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
        resolve fn _, %{id: id}, %{context: %{loader: loader, test_pid: test_pid}} ->
          loader
          |> Dataloader.load(:test, {:organization, test_pid}, id)
          |> on_load(fn loader ->
            {:ok, Dataloader.get(loader, :test, {:organization, test_pid}, id)}
          end)
        end
      end
    end

  end

  it "can resolve a field using the normal dataloader helper" do
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

    assert_receive(:loading)
    refute_receive(:loading)
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
    assert_receive(:loading)
    refute_receive(:loading)
  end

end
