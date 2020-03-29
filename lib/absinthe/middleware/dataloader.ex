if Code.ensure_loaded?(Dataloader) do
  defmodule Absinthe.Middleware.Dataloader do
    @behaviour Absinthe.Middleware
    @behaviour Absinthe.Plugin

    @impl Absinthe.Plugin
    def before_resolution(%{context: context} = exec) do
      context =
        with %{loader: loader} <- context do
          %{context | loader: Dataloader.run(loader)}
        end

      %{exec | context: context}
    end

    @impl Absinthe.Middleware
    def call(%{state: :unresolved} = resolution, {loader, callback}) do
      if !Dataloader.pending_batches?(loader) do
        resolution.context.loader
        |> put_in(loader)
        |> get_result(callback)
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

    @impl Absinthe.Plugin
    def after_resolution(exec) do
      exec
    end

    @impl Absinthe.Plugin
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
