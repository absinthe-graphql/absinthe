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

    def call(%{state: :unresolved} = resolution, {loader, callback}) do
      if !Dataloader.pending_batches?(loader) do
        get_result(resolution, callback)
      else
        %{
          resolution
          | context: Map.put(resolution.context, :loader, loader),
            state: :suspended,
            middleware: [{__MODULE__, callback} | resolution.middleware]
        }
      end
    end

    def call(%{state: :suspended} = resolution, callback) do
      get_result(resolution, callback)
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
