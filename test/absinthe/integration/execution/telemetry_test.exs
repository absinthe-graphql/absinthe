defmodule Elixir.Absinthe.Integration.Execution.TelemetryTest do
  use ExUnit.Case, async: true

  setup context do
    :telemetry.attach_many(
      context.test,
      [
        [:absinthe, :resolver],
        [:absinthe, :query]
      ],
      &__MODULE__.handle_event/4,
      %{}
    )

    on_exit(fn ->
      :telemetry.detach(context.test)
    end)

    :ok
  end

  def handle_event(event, measurements, metadata, config) do
    send(self(), {event, measurements, metadata, config})
  end

  defmodule TestSchema do
    use Absinthe.Schema

    object :object_thing do
      field :name, :string
    end

    query do
      field :object_thing, :object_thing do
        resolve fn _, _, _ -> {:ok, %{name: "Foo"}} end
      end

      field :async_thing, :string do
        arg :echo, :string
        resolve &TestSchema.resolve_async/3
      end
    end

    def resolve_async(_, %{echo: echo}, _) do
      async(fn -> {:ok, echo} end)
    end
  end

  test "Execute expected telemetry events" do
    query = """
    query CustomOperationName ($echo: String!) {
      asyncThing(echo: $echo)
      objectThing { name }
    }
    """

    {:ok, %{data: data}} = Absinthe.run(query, TestSchema, variables: %{"echo" => "ASYNC"})
    assert %{"asyncThing" => "ASYNC", "objectThing" => %{"name" => "Foo"}} == data

    assert_receive {[:absinthe, :query], measurements, meta, _config}

    assert is_number(measurements[:duration])
    assert System.convert_time_unit(meta[:start_time], :native, :millisecond)
    assert %Absinthe.Blueprint{} = meta[:blueprint]
    assert meta[:options][:schema] == TestSchema

    assert_receive {[:absinthe, :resolver], measurements, meta, _}

    assert is_number(measurements[:duration])
    assert System.convert_time_unit(meta[:start_time], :native, :millisecond)
    assert %Absinthe.Resolution{} = meta[:resolution]
    assert is_list(meta[:middleware])

    assert_receive {[:absinthe, :resolver], _, _, _}
    # Don't execute for resolvers that don't call a resolver function (ie: default `Map.get`)
    refute_receive {[:absinthe, :resolver], _, _, _}
  end
end
