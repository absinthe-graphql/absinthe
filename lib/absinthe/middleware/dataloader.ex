if Code.ensure_loaded?(Dataloader) do
  defmodule Absinthe.Middleware.Dataloader do
    @behaviour Absinthe.Middleware
    @behaviour Absinthe.Plugin

    def before_resolution(%{context: context} = exec) do
      context = Map.put_new(context, :values, %{})
      old_values = Map.keys(context[:values] || %{})

      values =
        Enum.zip(old_values, Dataloader.evaluate(old_values, single_pass: true)) |> Map.new()

      %{exec | context: Map.put(context, :values, values)}
    end

    def call(resolution, %Dataloader.Value{lazy?: false, value: value}) do
      Absinthe.Resolution.put_result(resolution, value)
    end

    def call(
          resolution = %{context: context},
          val = %Dataloader.Value{}
        ) do
      case Map.get(context.values, val) do
        %Dataloader.Value{lazy?: false, value: value} ->
          values = Map.delete(context.values, val)

          resolution = %{resolution | context: Map.put(context, :values, values)}
          Absinthe.Resolution.put_result(resolution, value)

        # replace by the new value
        new_val = %Dataloader.Value{lazy?: true} ->
          values =
            context.values
            |> Map.delete(val)
            |> Map.put(new_val, nil)

          %{
            resolution
            | context: Map.put(context, :values, values),
              state: :suspended,
              middleware: [{__MODULE__, val} | resolution.middleware]
          }

        nil ->
          values =
            context.values
            |> Map.put(val, nil)

          %{
            resolution
            | context: Map.put(context, :values, values),
              state: :suspended,
              middleware: [{__MODULE__, val} | resolution.middleware]
          }
      end
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