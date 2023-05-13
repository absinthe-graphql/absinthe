defmodule Absinthe.Middleware.DataloaderTest do
  use Absinthe.Case, async: true

  defmodule Schema do
    defmacro __using__(_opts) do
      quote do
        use Absinthe.Schema

        import Absinthe.Resolution.Helpers

        @organizations 1..3
                       |> Map.new(
                         &{&1,
                          %{
                            id: &1,
                            name: "Organization: ##{&1}"
                          }}
                       )
        @users 1..3
               |> Enum.map(
                 &%{
                   id: &1,
                   name: "User: ##{&1}",
                   organization_id: &1
                 }
               )

        @users_with_organization 1..3
                                 |> Enum.map(
                                   &%{
                                     id: &1,
                                     name: "User: ##{&1}",
                                     organization_id: &1,
                                     organization: %{
                                       id: &1,
                                       name: "Organization: ##{&1}"
                                     }
                                   }
                                 )

        def organizations(), do: @organizations

        defp batch_load({:organization, %{pid: test_pid}}, sources) do
          send(test_pid, :loading)

          Map.new(sources, fn src ->
            {src, Map.fetch!(@organizations, src.organization_id)}
          end)
        end

        def batch_dataloader(opts \\ []) do
          source = Dataloader.KV.new(&batch_load/2)
          Dataloader.add_source(Dataloader.new(opts), :test, source)
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

          field :foo_organization, :organization do
            resolve dataloader(
                      :test,
                      fn _, _, %{context: %{test_pid: pid}} ->
                        {:organization, %{pid: pid}}
                      end
                    )
          end

          field :bar_organization, :organization do
            resolve dataloader(:test, :organization, args: %{pid: self()}, use_parent: true)
          end

          field :bar_organization_name, :string do
            resolve dataloader(
                      :test,
                      :organization,
                      args: %{pid: self()},
                      callback: fn organization, _parent, _args ->
                        {:ok, organization.name}
                      end
                    )
          end

          field :bar_organization_state, :string do
            resolve dataloader(:test, :organization,
                      args: %{pid: self()},
                      callback: fn organization, _parent, _args, resolution ->
                        {:ok, "#{organization.name} - #{resolution.state}"}
                      end
                    )
          end
        end

        query do
          field :users, list_of(:user) do
            resolve fn _, _, _ -> {:ok, @users} end
          end

          field :users_with_organization, list_of(:user) do
            resolve fn _, _, _ -> {:ok, @users_with_organization} end
          end

          field :organization, :organization do
            arg :id, non_null(:integer)

            resolve fn _, %{id: id}, %{context: %{loader: loader, test_pid: test_pid}} ->
              loader
              |> Dataloader.load(:test, {:organization, %{pid: test_pid}}, %{
                organization_id: id
              })
              |> Dataloader.put(
                :test,
                {:organization, %{pid: self()}},
                %{organization_id: 123},
                %{}
              )
              |> on_load(fn loader ->
                {:ok,
                 Dataloader.get(loader, :test, {:organization, %{pid: test_pid}}, %{
                   organization_id: id
                 })}
              end)
            end
          end
        end
      end
    end
  end

  defmodule DefaultSchema do
    use Schema

    def context(ctx) do
      ctx
      |> Map.put_new(:loader, batch_dataloader())
      |> Map.merge(%{
        test_pid: self()
      })
    end
  end

  defmodule TuplesSchema do
    use Schema

    def context(ctx) do
      ctx
      |> Map.put_new(:loader, batch_dataloader(get_policy: :tuples))
      |> Map.merge(%{
        test_pid: self()
      })
    end
  end

  test "can resolve a field using the normal dataloader helper" do
    doc = """
    {
      users {
        organization: barOrganization {
          name
        }
      }
    }
    """

    expected_data = %{
      "users" => [
        %{"organization" => %{"name" => "Organization: #1"}},
        %{"organization" => %{"name" => "Organization: #2"}},
        %{"organization" => %{"name" => "Organization: #3"}}
      ]
    }

    assert {:ok, %{data: data}} = Absinthe.run(doc, DefaultSchema)
    assert expected_data == data

    assert_receive(:loading)
    refute_receive(:loading)
  end

  test "can resolve fields using dataloader helper with callback" do
    doc = """
    {
      users {
        organizationName: barOrganizationName
        organizationState: barOrganizationState
      }
    }
    """

    expected_data = %{
      "users" => [
        %{
          "organizationName" => "Organization: #1",
          "organizationState" => "Organization: #1 - unresolved"
        },
        %{
          "organizationName" => "Organization: #2",
          "organizationState" => "Organization: #2 - unresolved"
        },
        %{
          "organizationName" => "Organization: #3",
          "organizationState" => "Organization: #3 - unresolved"
        }
      ]
    }

    assert {:ok, %{data: data}} = Absinthe.run(doc, DefaultSchema)
    assert expected_data == data

    assert_receive(:loading)
    refute_receive(:loading)
  end

  test "can resolve a field when dataloader uses 'tuples' get_policy" do
    doc = """
    {
      users {
        organization: barOrganization {
          name
        }
      }
    }
    """

    expected_data = %{
      "users" => [
        %{"organization" => %{"name" => "Organization: #1"}},
        %{"organization" => %{"name" => "Organization: #2"}},
        %{"organization" => %{"name" => "Organization: #3"}}
      ]
    }

    assert {:ok, %{data: data}} = Absinthe.run(doc, TuplesSchema)
    assert expected_data == data

    assert_receive(:loading)
    refute_receive(:loading)
  end

  test "can resolve batched fields cross-query that have different data requirements" do
    doc = """
    {
      users {
        organization: fooOrganization {
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
        %{"organization" => %{"name" => "Organization: #3"}}
      ],
      "organization" => %{"id" => 1}
    }

    assert {:ok, %{data: data}} = Absinthe.run(doc, DefaultSchema)
    assert expected_data == data
    assert_receive(:loading)
    refute_receive(:loading)
  end

  test "using a cached field doesn't explode" do
    doc = """
    {
      organization(id: 1) {
        id
      }
    }
    """

    expected_data = %{"organization" => %{"id" => 1}}

    org = DefaultSchema.organizations()[1]

    # Get the dataloader, and warm the cache for the organization key we're going
    # to try to access via graphql.
    dataloader =
      DefaultSchema.batch_dataloader()
      |> Dataloader.put(:test, {:organization, %{pid: self()}}, %{organization_id: 1}, org)

    context = %{
      loader: dataloader
    }

    assert {:ok, %{data: data}} = Absinthe.run(doc, DefaultSchema, context: context)
    assert expected_data == data

    refute_receive(:loading)
  end

  test "use parent's pre-existing value when use_parent is true" do
    doc = """
    {
      usersWithOrganization {
        organization: barOrganization {
          name
        }
      }
    }
    """

    expected_data = %{
      "usersWithOrganization" => [
        %{"organization" => %{"name" => "Organization: #1"}},
        %{"organization" => %{"name" => "Organization: #2"}},
        %{"organization" => %{"name" => "Organization: #3"}}
      ]
    }

    assert {:ok, %{data: data}} = Absinthe.run(doc, DefaultSchema)
    assert expected_data == data

    refute_receive(:loading)
  end

  test "ignore parent's pre-existing value when use_parent is false (default)" do
    doc = """
    {
      usersWithOrganization {
        organization: fooOrganization {
          name
        }
      }
    }
    """

    expected_data = %{
      "usersWithOrganization" => [
        %{"organization" => %{"name" => "Organization: #1"}},
        %{"organization" => %{"name" => "Organization: #2"}},
        %{"organization" => %{"name" => "Organization: #3"}}
      ]
    }

    assert {:ok, %{data: data}} = Absinthe.run(doc, DefaultSchema)
    assert expected_data == data

    assert_receive(:loading)
    refute_receive(:loading)
  end
end
