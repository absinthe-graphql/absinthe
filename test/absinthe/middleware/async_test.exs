defmodule Absinthe.Middleware.AsyncTest do
  use Absinthe.Case, async: false

  defmodule Schema do
    use Absinthe.Schema

    query do
      field :async_thing, :string do
        resolve fn _, _, _ ->
          async(fn ->
            async(fn ->
              {:ok, "we async now"}
            end)
          end)
        end
      end

      field :other_async_thing, :string do
        resolve cool_async(fn _, _, _ ->
                  {:ok, "magic"}
                end)
      end

      field :returns_nil, :string do
        resolve cool_async(fn _, _, _ ->
                  {:ok, nil}
                end)
      end

      field :async_bare_thing_with_opts, :string do
        resolve fn _, _, _ ->
          task =
            Task.async(fn ->
              # Absinthe.AsyncTaskWrapper DISABLED
              {:ok, "bare task"}
            end)

          {:middleware, Elixir.Absinthe.Middleware.Async, {task, []}}
        end
      end

      field :async_bare_thing, :string do
        resolve fn _, _, _ ->
          task =
            Task.async(fn ->
              # Absinthe.AsyncTaskWrapper DISABLED
              {:ok, "bare task"}
            end)

          {:middleware, Elixir.Absinthe.Middleware.Async, task}
        end
      end
    end

    def cool_async(fun) do
      fn _source, _args, _info ->
        async(fn ->
          {:middleware, Absinthe.Resolution, fun}
        end)
      end
    end
  end

  test "can resolve a field using the bare api with opts" do
    doc = """
    {asyncBareThingWithOpts}
    """

    assert {:ok, %{data: %{"asyncBareThingWithOpts" => "bare task"}}} == Absinthe.run(doc, Schema)
  end

  test "can resolve a field using the bare api" do
    doc = """
    {asyncBareThing}
    """

    assert {:ok, %{data: %{"asyncBareThing" => "bare task"}}} == Absinthe.run(doc, Schema)
  end

  test "can resolve a field using the normal test helper" do
    doc = """
    {asyncThing}
    """

    assert {:ok, %{data: %{"asyncThing" => "we async now"}}} == Absinthe.run(doc, Schema)
  end

  test "can resolve a field using a cooler but probably confusing to some people helper" do
    doc = """
    {otherAsyncThing}
    """

    assert {:ok, %{data: %{"otherAsyncThing" => "magic"}}} == Absinthe.run(doc, Schema)
  end

  test "can return nil from an async field safely" do
    doc = """
    {returnsNil}
    """

    assert {:ok, %{data: %{"returnsNil" => nil}}} == Absinthe.run(doc, Schema)
  end

  defmodule TestAsyncTaskWrapper do
    @behaviour Absinthe.AsyncTaskWrapper

    @impl true
    def wrap(fun, %Absinthe.Resolution{} = res) do
      fn ->
        :telemetry.execute([__MODULE__], %{}, %{res: res})
        apply(fun, [])
      end
    end

    defp handle([__MODULE__], _, %{res: res}, pid), do: send(pid, {__MODULE__, res})

    def attach do
      atw_before = Application.get_env(:absinthe, :async_task_wrapper)
      Application.put_env(:absinthe, :async_task_wrapper, __MODULE__)
      :telemetry.attach(__MODULE__, [__MODULE__], &handle/4, self())

      on_exit(make_ref(), fn ->
        Application.put_env(:absinthe, :async_task_wrapper, atw_before)
        :telemetry.detach(__MODULE__)
      end)
    end

    def collect(acc \\ []) do
      receive do
        {__MODULE__, res} -> collect(acc ++ [res])
      after
        10 -> acc
      end
    end
  end

  describe "while config :absinthe, async_task_wrapper: ..." do
    setup do
      TestAsyncTaskWrapper.attach()
      :ok
    end

    test "can resolve a field using the bare api with opts, with no async wrapping" do
      doc = """
      {asyncBareThingWithOpts}
      """

      assert {:ok, %{data: %{"asyncBareThingWithOpts" => "bare task"}}} ==
               Absinthe.run(doc, Schema)

      assert TestAsyncTaskWrapper.collect() |> length() == 0
    end

    test "can resolve a field using the bare api, with no async wrapping" do
      doc = """
      {asyncBareThing}
      """

      assert {:ok, %{data: %{"asyncBareThing" => "bare task"}}} == Absinthe.run(doc, Schema)
      assert TestAsyncTaskWrapper.collect() |> length() == 0
    end

    test "can resolve a field using the normal test helper" do
      doc = """
      {asyncThing}
      """

      assert {:ok, %{data: %{"asyncThing" => "we async now"}}} == Absinthe.run(doc, Schema)
      # Twice because nested use of async macro, but the resolution struct is the same:
      assert [acc1, acc2] = TestAsyncTaskWrapper.collect()
      assert acc2 == acc1
    end

    test "can resolve a field using a cooler but probably confusing to some people helper" do
      doc = """
      {otherAsyncThing}
      """

      assert {:ok, %{data: %{"otherAsyncThing" => "magic"}}} == Absinthe.run(doc, Schema)
      assert TestAsyncTaskWrapper.collect() |> length() == 1
    end

    test "can return nil from an async field safely" do
      doc = """
      {returnsNil}
      """

      assert {:ok, %{data: %{"returnsNil" => nil}}} == Absinthe.run(doc, Schema)
      assert TestAsyncTaskWrapper.collect() |> length() == 1
    end
  end
end
