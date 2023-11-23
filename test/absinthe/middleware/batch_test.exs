defmodule Absinthe.Middleware.BatchTest do
  use Absinthe.Case, async: true

  defmodule Schema do
    use Absinthe.Schema

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

      field :ctx, :string do
        resolve fn _, _, _ ->
          batch({__MODULE__, :otel_ctx}, nil, fn batch ->
            {:ok, batch}
          end)
        end
      end
    end

    def by_id(_, ids) do
      Map.take(@organizations, ids)
    end

    def otel_ctx(_, _) do
      OpenTelemetry.Ctx.get_value("stored_value", nil)
    end
  end

  test "can resolve a field using the normal async helper" do
    doc = """
    {
      users {
        organization {
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

    assert {:ok, %{data: data}} = Absinthe.run(doc, Schema)
    assert expected_data == data
  end

  test "can resolve batched fields cross-query that have different data requirements and should emit telemetry events",
       %{test: test} do
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
        %{"organization" => %{"name" => "Organization: #3"}}
      ],
      "organization" => %{"id" => 1}
    }

    :ok =
      :telemetry.attach_many(
        "#{test}",
        [
          [:absinthe, :middleware, :batch, :start],
          [:absinthe, :middleware, :batch, :stop]
        ],
        &Absinthe.TestTelemetryHelper.send_to_pid/4,
        nil
      )

    assert {:ok, %{data: data}} = Absinthe.run(doc, Schema)
    assert expected_data == data

    assert_receive {:telemetry_event,
                    {[:absinthe, :middleware, :batch, :start], %{system_time: _},
                     %{id: _, batch_fun: _, batch_opts: _, batch_data: _}, _}}

    assert_receive {:telemetry_event,
                    {[:absinthe, :middleware, :batch, :stop], %{duration: _},
                     %{id: _, batch_fun: _, batch_opts: _, batch_data: _, result: _}, _}}
  end

  test "propagates the OTel context" do
    doc = """
    {ctx}
    """

    OpenTelemetry.Ctx.set_value("stored_value", "some_value")

    assert {:ok, %{data: %{"ctx" => "some_value"}}} == Absinthe.run(doc, Schema)
  end
end
