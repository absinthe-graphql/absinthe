if Code.ensure_loaded?(Dataloader) do
  defmodule Absinthe.Middleware.Dataloader do
    @behaviour Absinthe.Middleware
    @behaviour Absinthe.Plugin

    def before_resolution(%{context: context} = exec) do
      context = Map.put_new(context, :values, %{})
      unevaluated_values = Map.keys(context[:values] || %{})

      evaluated_values =
        unevaluated_values
        |> Enum.zip(Dataloader.evaluate_single_pass(unevaluated_values))
        |> Map.new()

      %{exec | context: Map.put(context, :values, evaluated_values)}
    end

    defp get_resolution(
           %Dataloader.Value{lazy?: false, value: value},
           resolution = %{context: context},
           val
         ) do
      values = Map.delete(context.values, val)

      %{resolution | context: Map.put(context, :values, values)}
      |> Absinthe.Resolution.put_result(value)
    end

    defp get_resolution(
           cached_val = %Dataloader.Value{lazy?: true},
           resolution = %{context: context},
           val
         ) do
      values =
        context.values
        |> Map.delete(val)
        |> Map.put(cached_val, nil)

      %{
        resolution
        | context: Map.put(context, :values, values),
          state: :suspended,
          middleware: [{__MODULE__, val} | resolution.middleware]
      }
    end

    defp get_resolution(
           nil,
           resolution = %{context: context},
           val = %Dataloader.Value{lazy?: true}
         ) do
      values = Map.put(context.values, val, nil)

      %{
        resolution
        | context: Map.put(context, :values, values),
          state: :suspended,
          middleware: [{__MODULE__, val} | resolution.middleware]
      }
    end

    def call(resolution, %Dataloader.Value{lazy?: false, value: value}) do
      Absinthe.Resolution.put_result(resolution, value)
    end

    def call(
          resolution = %{context: context},
          val = %Dataloader.Value{}
        ) do
      get_resolution(context[:values][val], resolution, val)
    end

    def after_resolution(exec) do
      exec
    end

    def pipeline(pipeline, exec) do
      with true <- exec.context[:values] != %{} do
        [Absinthe.Phase.Document.Execution.Resolution | pipeline]
      else
        _ -> pipeline
      end
    end
  end
end