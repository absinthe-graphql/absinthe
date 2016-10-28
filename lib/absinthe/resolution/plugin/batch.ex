defmodule Absinthe.Resolution.Plugin.Batch do
  @moduledoc """
  """

  @behaviour Absinthe.Resolution.Plugin

  def before_resolution(acc) do
    case acc do
      %{__MODULE__ => _} ->
        put_in(acc[__MODULE__][:input], [])
      _ ->
        Map.put(acc, __MODULE__, %{input: [], output: %{}})
    end
  end

  def init({batch_fun, field_data, post_batch_fun}, acc) do
    acc = update_in(acc[__MODULE__][:input], fn
      nil -> [{batch_fun, field_data}]
      data -> [{batch_fun, field_data} | data]
    end)

    {{batch_fun, post_batch_fun}, acc}
  end

  def after_resolution(acc) do
    if input = acc[__MODULE__][:input] do
      put_in(acc[__MODULE__][:output], do_batching(input))
    else
      acc
    end
  end

  defp do_batching(input) do
    input
    |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
    |> Enum.map(fn {batch_fun, batch_data}->
      Task.async(fn ->
        {batch_fun, call_batch_fun(batch_fun, batch_data)}
      end)
    end)
    |> Map.new(&Task.await(&1))
  end

  def call_batch_fun({module, fun}, batch_data) do
    call_batch_fun({module, fun, []}, batch_data)
  end
  def call_batch_fun({module, fun, config}, batch_data) do
    apply(module, fun, [config, batch_data])
  end

  # If the flag is set we need to do another resolution phase.
  # otherwise, we do not
  def pipeline(pipeline, acc) do
    case acc[__MODULE__][:input] do
      [_|_] ->
        [Absinthe.Phase.Document.Execution.Resolution | pipeline]
      _ ->
        pipeline
    end
  end

  def resolve({batch_fun, post_batch_fun}, acc) do
    batch_data_for_fun =
      acc
      |> Map.fetch!(__MODULE__)
      |> Map.fetch!(:output)
      |> Map.fetch!(batch_fun)

    {post_batch_fun.(batch_data_for_fun), acc}
  end
end
