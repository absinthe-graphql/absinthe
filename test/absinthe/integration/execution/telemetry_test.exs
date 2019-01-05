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

    {:ok, %{data: data}} =
      Absinthe.run(query, TestSchema, analyze_complexity: true, variables: %{"echo" => "ASYNC"})

    assert %{"asyncThing" => "ASYNC", "objectThing" => %{"name" => "Foo"}} == data

    assert_receive {[:absinthe, :query], measurements, meta, _config}

    assert measurements[:duration] |> is_number()
    assert System.convert_time_unit(measurements[:start_time], :native, :millisecond)
    assert meta[:query] == query
    assert meta[:variables]["echo"] == "ASYNC"
    assert meta[:schema] == TestSchema
    assert meta[:operation_complexity] == 3
    assert meta[:operation_type] == :query
    assert meta[:operation_name] == "CustomOperationName"

    assert_receive {[:absinthe, :resolver], measurements, %{path: ["asyncThing"]} = meta, _}

    assert measurements[:duration] |> is_number()
    assert System.convert_time_unit(measurements[:start_time], :native, :millisecond)
    assert meta[:path] == ["asyncThing"]
    assert meta[:schema] == TestSchema
    assert meta[:arguments][:echo] == "ASYNC"
    assert meta[:mfa] == {TestSchema, :resolve_async, 3}
    assert meta[:path] |> is_list()
    assert meta[:field_name] == "asyncThing"
    assert meta[:field_type] == "String"
    assert meta[:parent_type] == "RootQueryType"

    assert_receive {[:absinthe, :resolver], _, %{path: ["objectThing"]}, _}

    # Don't execute for resolvers that don't call a resolver function (ie: default `Map.get`)
    refute_receive {[:absinthe, :resolver], _, %{path: ["objectThing", "name"]}, _}
  end
end
