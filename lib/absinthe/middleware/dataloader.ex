if Code.ensure_loaded?(Dataloader) do
  defmodule Absinthe.Middleware.Dataloader do
    @behaviour Absinthe.Middleware
    @behaviour Absinthe.Plugin

    def before_resolution(%{context: context} = exec) do
      context =
        with %{loader: loader} <- context do
          %{context | loader: Dataloader.run(loader)}
        end

      %{exec | context: context}
    end

    def call(%{state: :unresolved} = resolution, {:dataloader, loader, callback}) do
      previous_loader_state = resolution.context.loader

      if previous_loader_state == loader || !Dataloader.pending_batches?(loader) do
        get_result(resolution, callback)
      else
        %{
          resolution
          | context: Map.put(resolution.context, :loader, loader),
            state: :suspended,
            middleware: [{__MODULE__, {:dataloader, callback}} | resolution.middleware]
        }
      end
    end

    def call(%{state: :suspended} = resolution, {:dataloader, callback}) do
      get_result(resolution, callback)
    end

    def call(
          resolution = %{value: %Lazyloader.Deferrable{evaluated?: true, value: value}},
          _key
        ) do
      Absinthe.Resolution.put_result(resolution, value)
    end

    def call(resolution = %{value: deferrable = %Lazyloader.Deferrable{}}, _key) do
      case Lazyloader.Deferrable.run_callbacks(deferrable, resolution.context.dataloader, nil) do
        %Lazyloader.Deferrable{evaluated?: true, value: value} ->
          Absinthe.Resolution.put_result(resolution, value)

        %Lazyloader.Deferrable{} = result ->
          %{
            resolution
            | context:
                Map.put(
                  resolution.context,
                  :loader,
                  Lazyloader.Deferrable.apply_operations(result.dataloader, result)
                ),
              state: :suspended,
              value: result,
              middleware: [__MODULE__ | resolution.middleware]
          }
      end
    end

    def call(res, _key), do: res

    defp get_result(resolution, callback) do
      value = callback.(resolution.context.loader)
      Absinthe.Resolution.put_result(resolution, value)
    end

    def after_resolution(exec) do
      exec
    end

    def pipeline(pipeline, exec) do
      with %{loader: loader} <- exec.context,
           true <- Dataloader.pending_batches?(loader) do
        [Absinthe.Phase.Document.Execution.Resolution | pipeline]
      else
        _ -> pipeline
      end
    end
  end
end