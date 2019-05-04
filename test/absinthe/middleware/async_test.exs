defmodule Absinthe.Middleware.AsyncTest do
  use Absinthe.Case, async: true

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
              {:ok, "bare task"}
            end)

          {:middleware, Elixir.Absinthe.Middleware.Async, {task, []}}
        end
      end

      field :async_bare_thing, :string do
        resolve fn _, _, _ ->
          task =
            Task.async(fn ->
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
end
