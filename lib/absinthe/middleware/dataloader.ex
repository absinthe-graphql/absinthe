if Code.ensure_loaded?(Dataloader) do
  defmodule Absinthe.Middleware.Dataloader do
    @behaviour Absinthe.Middleware
    @behaviour Absinthe.Plugin

    @dataloader_start_event [:absinthe, :dataloader, :resolve, :start]
    @dataloader_stop_event [:absinthe, :dataloader, :resolve, :stop]

    @impl Absinthe.Plugin
    def before_resolution(%{context: context} = exec) do
      context =
        with %{loader: loader} <- context do
          start_time = System.monotonic_time()

          emit_start_event(start_time, exec, loader)
          updated_loader = Dataloader.run(loader)
          emit_stop_event(start_time, exec, loader)

          %{context | loader: updated_loader}
        end

      %{exec | context: context}
    end

    defp emit_start_event(start_time, blueprint, loader) do
      if Dataloader.pending_batches?(loader) do
        :telemetry.execute(
          @dataloader_start_event,
          %{start_time: start_time},
          %{blueprint: blueprint}
        )
      end
    end

    defp emit_stop_event(start_time, blueprint, loader) do
      if Dataloader.pending_batches?(loader) do
        :telemetry.execute(
          @dataloader_stop_event,
          %{duration: System.monotonic_time() - start_time},
          %{blueprint: blueprint}
        )
      end
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
