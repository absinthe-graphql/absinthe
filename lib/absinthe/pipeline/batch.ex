defmodule Absinthe.Pipeline.Batch do
  alias Absinthe.Phase.Document.Execution

  def resolve(blueprints, options) do
    schema = Keyword.fetch!(options, :schema)
    plugins = schema.plugins()

    acc = init_acc(blueprints)
    resolution_phase = {Execution.Resolution, [plugin_callbacks: false] ++ options}

    do_resolve(blueprints, [resolution_phase], acc, plugins)
  end

  defp do_resolve(blueprints, phases, acc, plugins) do
    acc = Enum.reduce(plugins, acc, fn plugin, acc ->
      plugin.before_resolution(acc)
    end)

    {blueprints, acc} = execute(blueprints, phases, [], acc)

    acc = Enum.reduce(plugins, acc, fn plugin, acc ->
      plugin.after_resolution(acc)
    end)

    plugins
    |> Absinthe.Plugin.pipeline(acc)
    |> case do
      [] ->
        blueprints
      pipeline ->
        do_resolve(blueprints, pipeline, acc, plugins)
    end
  end

  defp execute([], _phases, results, resolution_acc) do
    {:lists.reverse(results), resolution_acc}
  end
  defp execute([bp | rest], phases, results, resolution_acc) do
    bp =
      bp
      |> update_resolution_acc(resolution_acc)
      |> run_pipeline(phases)

    resolution_acc = bp.resolution.acc

    execute(rest, phases, [bp | results], resolution_acc)
  end

  defp run_pipeline(bp, phases) do
    case Absinthe.Pipeline.run(phases, bp) do
     {:ok, blueprint, _} ->
       blueprint
     result ->
       raise pipeline_error(result)
   end
  end

  defp update_resolution_acc(%{resolution: resolution} = bp, acc) do
    %{bp | resolution: %{resolution | acc: acc}}
  end

  defp init_acc(blueprints) do
    Enum.reduce(blueprints, %{}, &Map.merge(&1.resolution.acc, &2))
  end

  defp pipeline_error(result) do
    """
    Batch Pipeline Run Error

    Invalid return result: #{inspect result}

    The resolution phase inside a pipeline run should only return the blueprint.

    This is largely an internal error, contact @benwilson512 on slack if you see
    this.
    """
  end
end
