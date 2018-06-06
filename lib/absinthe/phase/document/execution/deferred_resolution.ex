defmodule Absinthe.Phase.Document.Execution.DeferredResolution do
  @moduledoc false

  # Perform resolution on previously deferred fields

  alias Absinthe.{Blueprint, Phase}
  alias Phase.Document.Execution.Resolution

  use Absinthe.Phase

  @spec run(map(), Keyword.t()) :: Phase.result_t()
  def run(input, _options \\ []) do
    {:ok, resolve_field(input)}
  end

  defp resolve_field(input) do
    {result, _} = perform_deferred_resolution(input)

    %Blueprint{
      execution: %{input.execution | result: result},
      result: %{path: make_path(input.resolution.path)}}
  end

  defp perform_deferred_resolution(input) do
    # Perform resolution using the standard resolver pipeline functionality
    Resolution.do_resolve_field(
      input.resolution,
      input.resolution.source,
      input.resolution.path
    )
  end

  defp make_path(path) do
    path
    |> Enum.map(&to_path_field/1)
    |> Enum.filter(fn e -> e != nil end)
    |> Enum.reverse()
  end

  defp to_path_field(index) when is_integer(index), do: index
  defp to_path_field(%{name: name}), do: name
end
