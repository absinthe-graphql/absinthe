defmodule Absinthe.Middleware.IncrementalComplexity do
  @moduledoc """
  Middleware to enforce complexity limits for incremental delivery.

  Add this middleware to your schema to automatically check and enforce
  complexity limits for queries with @defer and @stream.

  ## Usage

      defmodule MySchema do
        use Absinthe.Schema

        def middleware(middleware, _field, _object) do
          [Absinthe.Middleware.IncrementalComplexity | middleware]
        end
      end

  ## Configuration

  Pass a config map with limits:

      config = %{
        max_complexity: 500,
        max_chunk_complexity: 100,
        max_defer_operations: 5
      }

      def middleware(middleware, _field, _object) do
        [{Absinthe.Middleware.IncrementalComplexity, config} | middleware]
      end
  """

  @behaviour Absinthe.Middleware

  alias Absinthe.Incremental.Complexity

  def call(resolution, config) do
    blueprint = resolution.private[:blueprint]

    if blueprint && should_check?(resolution) do
      case Complexity.check_limits(blueprint, config) do
        :ok ->
          resolution

        {:error, reason} ->
          Absinthe.Resolution.put_result(
            resolution,
            {:error, format_error(reason)}
          )
      end
    else
      resolution
    end
  end

  defp should_check?(resolution) do
    # Only check on the root query/mutation/subscription
    resolution.path == []
  end

  defp format_error({:complexity_exceeded, actual, limit}) do
    "Query complexity #{actual} exceeds maximum of #{limit}"
  end

  defp format_error({:too_many_defers, count}) do
    "Too many defer operations: #{count}"
  end

  defp format_error({:too_many_streams, count}) do
    "Too many stream operations: #{count}"
  end

  defp format_error({:defer_too_deep, depth}) do
    "Defer nesting too deep: #{depth} levels"
  end

  defp format_error({:initial_too_complex, actual, limit}) do
    "Initial response complexity #{actual} exceeds maximum of #{limit}"
  end

  defp format_error({:chunk_too_complex, :defer, label, actual, limit}) do
    label_str = if label, do: " (#{label})", else: ""
    "Deferred fragment#{label_str} complexity #{actual} exceeds maximum of #{limit}"
  end

  defp format_error({:chunk_too_complex, :stream, label, actual, limit}) do
    label_str = if label, do: " (#{label})", else: ""
    "Streamed field#{label_str} complexity #{actual} exceeds maximum of #{limit}"
  end

  defp format_error(reason) do
    "Complexity check failed: #{inspect(reason)}"
  end
end
