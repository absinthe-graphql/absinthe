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

    def call(resolution, deferrable = %Lazyloader.Deferrable{}) do
      # we manually run the dataloader at the start of the resolution, so just evaluate the
      # deferrable as far as we can without running the dataloader
      case Lazyloader.Deferrable.evaluate_once(
             deferrable,
             dataloader: resolution.context.loader,
             run_dataloader: false
           ) do
        %Lazyloader.Deferrable{evaluated?: true, value: value} ->
          Absinthe.Resolution.put_result(resolution, value)

        %Lazyloader.Deferrable{dataloader: loader} = result ->
          %{
            resolution
            | context:
                Map.put(
                  resolution.context,
                  :loader,
                  loader
                ),
              state: :suspended,
              value: result,
              middleware: [{__MODULE__, result} | resolution.middleware]
          }
      end
    end

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