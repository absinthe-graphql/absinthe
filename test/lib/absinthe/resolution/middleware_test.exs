defmodule Absinthe.Resolution.MiddlewareTest do
  use Absinthe.Case, async: true

  defmodule Timing do
    def call(res, :start) do
      # place start time on res
      res
    end

    def call(res, :end) do
      # put total time on res
      res
    end
  end

  defmodule Auth do
    def call(res, _) do
      if Enum.any?(res.middleware, &match?({:public, _}, &1)) do
        res
      else
        case res.context do
          %{current_user: _} ->
            res
          _ ->
            %{res | state: :halt, result: {:error, "unauthorized"}}
        end
      end
    end
  end

  defmodule Schema do
    use Absinthe.Schema

    alias Absinthe.Resolution.MiddlewareTest

    def middleware(field, %Absinthe.Type.Object{identifier: :query}) do
      field
      |> Map.update!(:middleware, &[{MiddlewareTest.Auth, []} | &1])
      |> timing_middleware
    end
    def middleware(object, field) do
      object
      |> Absinthe.Schema.default_middleware(field)
      |> timing_middleware
    end

    defp timing_middleware(field) do
      field
      |> Map.update!(:middleware, &([{MiddlewareTest.Timing, :start} | &1] ++ [{MiddlewareTest.Timing, :end}]))
    end

    query do
      field :authenticated, :string do
        resolve fn _, _, _ ->
          {:ok, "hello"}
        end
      end

      field :public, :string do
        plug :public
        resolve fn _, _, _ ->
          {:ok, "world"}
        end
      end
    end
  end

  test "foo" do

  end
end
