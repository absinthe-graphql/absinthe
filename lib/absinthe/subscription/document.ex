defmodule Absinthe.Subscription.Document do
  @moduledoc """
  A subscription document that is ready to be executed.
  """
  alias Absinthe.Pipeline
  alias Absinthe.Phase

  defstruct [:topic, :key_strategy, :field, :initial_phases, :source, __private__: []]

  @type t :: %__MODULE__{
    topic: atom(),
    field: atom(),
    key_strategy: term | (term -> term),
    initial_phases: [Phase.t()],
    source: String.t(),
    __private__: Keyword.t()
  }

  @doc false
  def pipeline(document, options) do
    pipeline =
      document.initial_phases
      |> Pipeline.replace(
        Phase.Telemetry,
        {Phase.Telemetry, event: [:subscription, :publish, :start]}
      )
      |> Pipeline.without(Phase.Subscription.SubscribeSelf)
      |> Pipeline.insert_before(
        Phase.Document.Execution.Resolution,
        {Phase.Document.OverrideRoot, options}
      )
      |> Pipeline.upto(Phase.Document.Execution.Resolution)

    [
      pipeline,
      [Phase.Document.Result, {Phase.Telemetry, event: [:subscription, :publish, :stop]}]
    ]
  end
end
