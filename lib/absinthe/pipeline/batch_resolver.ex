defmodule Absinthe.Pipeline.BatchResolver do
  alias Absinthe.Phase.Document.Execution

  require Logger

  @moduledoc false

  def run(blueprints, options) do
    schema = Keyword.fetch!(options, :schema)
    plugins = schema.plugins()

    acc = init_acc(blueprints)
    resolution_phase = {Execution.Resolution, [plugin_callbacks: false] ++ options}

    do_resolve(blueprints, [resolution_phase], acc, plugins, resolution_phase, options)
  end

  defp do_resolve(blueprints, phases, acc, plugins, resolution_phase_template, options) do
    acc = Enum.reduce(plugins, acc, fn plugin, acc ->
      plugin.before_resolution(acc)
    end)

    abort_on_error? = Keyword.get(options, :abort_on_error, true)

    {blueprints, acc} = execute(blueprints, phases, abort_on_error?, [], acc)

    acc = Enum.reduce(plugins, acc, fn plugin, acc ->
      plugin.after_resolution(acc)
    end)

    plugins
    |> Absinthe.Plugin.pipeline(acc)
    |> case do
      [] ->
        blueprints
      pipeline ->
        pipeline = Absinthe.Pipeline.replace(pipeline, Execution.Resolution, resolution_phase_template)
        do_resolve(blueprints, pipeline, acc, plugins, resolution_phase_template, options)
    end
  end

  defp execute([], _phases, _abort_on_error?, results, resolution_acc) do
    {:lists.reverse(results), resolution_acc}
  end
  defp execute([bp | rest], phases, abort_on_error?, results, resolution_acc) do
    bp
    |> update_resolution_acc(resolution_acc)
    |> run_pipeline(phases, abort_on_error?)
    |> case do
      {:ok, bp} ->
        resolution_acc = bp.resolution.acc
        execute(rest, phases, abort_on_error?, [bp | results], resolution_acc)
      :error ->
        execute(rest, phases, abort_on_error?, [:error | results], resolution_acc)
    end
  end

  defp run_pipeline(bp, phases, _abort_on_error? = true) do
    {:ok, blueprint, _} = Absinthe.Pipeline.run(bp, phases)
    {:ok, blueprint}
  end

  defp run_pipeline(bp, phases, _) do
    {:ok, blueprint, _} = Absinthe.Pipeline.run(bp, phases)
    {:ok, blueprint}
  rescue
    e ->
      pipeline_error(e)
      :error
  end

  defp update_resolution_acc(%{resolution: resolution} = bp, acc) do
    %{bp | resolution: %{resolution | acc: acc}}
  end

  defp init_acc(blueprints) do
    Enum.reduce(blueprints, %{}, &Map.merge(&1.resolution.acc, &2))
  end

  defp pipeline_error(exception) do
    message = Exception.message(exception)
    stacktrace = System.stacktrace |> Exception.format_stacktrace

    Logger.error("""
    #{message}

    #{stacktrace}
    """)
  end
end
