defmodule Absinthe.Phase.Telemetry do
  @moduledoc """
  Gather and report telemetry about an operation.
  """
  @operation_start [:absinthe, :execute, :operation, :start]
  @operation [:absinthe, :execute, :operation]

  @subscription_start [:absinthe, :subscription, :publish, :start]
  @subscription [:absinthe, :subscription, :publish]

  use Absinthe.Phase

  def run(blueprint, [:execute, :operation, :start]) do
    id = :erlang.unique_integer()
    start_time = System.system_time()
    start_time_mono = System.monotonic_time()

    :telemetry.execute(@operation_start, %{start_time: start_time}, %{id: id})

    {:ok,
     %{
       blueprint
       | source: blueprint.input,
         telemetry: %{
           id: id,
           start_time: start_time,
           start_time_mono: start_time_mono
         }
     }}
  end

  def run(blueprint, [:subscription, :publish, :start]) do
    id = :erlang.unique_integer()
    start_time = System.system_time()
    start_time_mono = System.monotonic_time()

    :telemetry.execute(@subscription_start, %{start_time: start_time}, %{id: id})

    {:ok,
     %{
       blueprint
       | telemetry: %{
           id: id,
           start_time: start_time,
           start_time_mono: start_time_mono
         }
     }}
  end

  def run(blueprint, [:subscription, :publish]) do
    end_time_mono = System.monotonic_time()

    with %{id: id, start_time: start_time, start_time_mono: start_time_mono} <-
           blueprint.telemetry do
      :telemetry.execute(
        @subscription,
        %{duration: end_time_mono - start_time_mono},
        %{
          id: id,
          start_time: start_time,
          blueprint: blueprint
        }
      )
    end

    {:ok, blueprint}
  end

  def run(blueprint, [:execute, :operation, options]) do
    end_time_mono = System.monotonic_time()

    with %{id: id, start_time: start_time, start_time_mono: start_time_mono} <-
           blueprint.telemetry do
      :telemetry.execute(
        @operation,
        %{duration: end_time_mono - start_time_mono},
        %{
          id: id,
          start_time: start_time,
          blueprint: blueprint,
          options: options
        }
      )
    end

    {:ok, blueprint}
  end
end
