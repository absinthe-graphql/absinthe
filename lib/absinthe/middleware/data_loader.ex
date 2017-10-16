if Code.ensure_loaded?(DataLoader) do
  defmodule Absinthe.Middleware.DataLoader do
    @behaviour Absinthe.Middleware
    @behaviour Absinthe.Plugin

    def before_resolution(%{context: context} = exec) do
      context = with %{loader: loader} <- context do
        %{context | loader: DataLoader.run(loader)}
      end

      %{exec | context: context}
    end

    def call(%{state: :unresolved} = resolution, {loader, callback}) do
      %{resolution |
        context: Map.put(resolution.context, :loader, loader),
        state: :suspended,
        middleware: [{__MODULE__, callback} | resolution.middleware]
      }
    end
    def call(%{state: :suspended} = resolution, callback) do
      value = callback.(resolution.context.loader)
      Absinthe.Resolution.put_result(resolution, value)
    end

    def after_resolution(exec) do
      exec
    end

    def pipeline(pipeline, exec) do
      with %{loader: loader} <- exec.context,
      true <- DataLoader.pending_batches?(loader) do
        [Absinthe.Phase.Document.Execution.Resolution | pipeline]
      else
        _ -> pipeline
      end
    end

  end
end
