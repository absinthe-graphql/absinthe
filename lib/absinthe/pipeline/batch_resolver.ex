defmodule Absinthe.Pipeline.BatchResolver do
  alias Absinthe.Phase.Document.Execution

  require Logger

  @moduledoc false

  def run([], _), do: []

  def run([bp | _] = blueprints, options) do
    {initial_phases, options} = Keyword.pop(options, :initial_phases, [])
    schema = Keyword.fetch!(options, :schema)
    plugins = schema.plugins()

    acc = init(blueprints, :acc)
    ctx = init(blueprints, :context)

    # This will serve as a generic cross document execution struct
    exec = %{
      bp.execution
      | acc: acc,
        context: ctx,
        fragments: %{},
        validation_errors: [],
        result: nil
    }

    resolution_phase = {Execution.Resolution, [plugin_callbacks: false] ++ options}
    phases = initial_phases ++ [resolution_phase]

    do_resolve(blueprints, phases, exec, plugins, resolution_phase, options)
  end

  defp init(blueprints, attr) do
    Enum.reduce(blueprints, %{}, &Map.merge(Map.fetch!(&1.execution, attr), &2))
  end

  defp do_resolve(blueprints, phases, exec, plugins, resolution_phase_template, options) do
    exec =
      Enum.reduce(plugins, exec, fn plugin, exec ->
        plugin.before_resolution(exec)
      end)

    abort_on_error? = Keyword.get(options, :abort_on_error, true)

    {blueprints, exec} = execute(blueprints, phases, abort_on_error?, [], exec)

    exec =
      Enum.reduce(plugins, exec, fn plugin, exec ->
        plugin.after_resolution(exec)
      end)

    plugins
    |> Absinthe.Plugin.pipeline(exec)
    |> case do
      [] ->
        blueprints

      pipeline ->
        pipeline =
          Absinthe.Pipeline.replace(pipeline, Execution.Resolution, resolution_phase_template)

        do_resolve(blueprints, pipeline, exec, plugins, resolution_phase_template, options)
    end
  end

  defp execute([], _phases, _abort_on_error?, results, exec) do
    {:lists.reverse(results), exec}
  end

  defp execute([bp | rest], phases, abort_on_error?, results, exec) do
    bp
    |> update_exec(exec)
    |> run_pipeline(phases, abort_on_error?)
    |> case do
      {:ok, bp} ->
        %{acc: acc, context: ctx} = bp.execution
        exec = %{exec | acc: acc, context: ctx}
        execute(rest, phases, abort_on_error?, [bp | results], exec)

      :error ->
        execute(rest, phases, abort_on_error?, [:error | results], exec)
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
      pipeline_error(e, System.stacktrace())
      :error
  end

  defp update_exec(%{execution: execution} = bp, %{acc: acc, context: ctx}) do
    %{bp | execution: %{execution | acc: acc, context: ctx}}
  end

  def pipeline_error(exception, trace) do
    message = Exception.message(exception)
    stacktrace = trace |> Exception.format_stacktrace()

    Logger.error("""
    #{message}

    #{stacktrace}
    """)
  end
end
