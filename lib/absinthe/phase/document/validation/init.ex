defmodule Absinthe.Phase.Document.Validation.Init do
  @moduledoc false

  # Init validation

  alias Absinthe.{Blueprint, Phase}

  use Absinthe.Phase

  @doc """
  Run the validation.
  """
  @spec run(Blueprint.t(), Keyword.t()) :: Phase.result_t()
  def run(blueprint, _options \\ []) do
    id = :erlang.unique_integer()
    system_time = System.system_time()
    start_time_mono = System.monotonic_time()

    :telemetry.execute(
      [:absinthe, :validate, :start],
      %{system_time: system_time},
      %{telemetry_span_context: id, blueprint: blueprint}
    )

    {:ok, %{blueprint | telemetry: %{id: id, start_time_mono: start_time_mono}}}
  end
end
