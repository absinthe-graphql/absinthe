defmodule Absinthe.Pipeline do

  alias Absinthe.{Pipeline, Phase}

  @enforce_keys [:phases]
  defstruct [
    :phases,
    extensible: true
  ]

  @type t :: %__MODULE__{
    phases: [Pipeline.Phase.t],
    extensible: boolean
  }

  @spec run(any, t) :: {:ok, any} | {:error, Phase.Error.t}
  def run(input, pipeline) do
    do_run(input, pipeline)
  end

  @spec do_run(any, t) :: {:ok, any} | {:error, Phase.Error.t}
  defp do_run(input, %Pipeline{phases: []}) do
    {:ok, input}
  end
  defp do_run(input, %Pipeline{phases: [phase | rest]} = pipeline) do
    next_pipeline = %{pipeline | phases: rest}
    case phase.run(input, next_pipeline) do
      {:ok, result, requested_pipeline} ->
        if next_pipeline.extensible do
          do_run(result, requested_pipeline)
        else
          do_run(result, next_pipeline)
        end
      {:error, %Phase.Error{}} = result ->
        result
      {:error, message} ->
        {:error, %Phase.Error{message: message, phase: phase}}
    end
  end

  @spec locked([Phase.t]) :: t
  def locked(phases) do
    %__MODULE__{
      phases: phases,
      extensible: false
    }
  end

  @spec default :: t
  def default do
    %__MODULE__{
      phases: [
        Absinthe.Phase.Parse,
        Absinthe.Phase.Blueprint
      ]
    }
  end

  @spec prepend(t, Pipeline.Step.t) :: t
  def prepend(pipeline, step) do
    update_in(pipeline.steps, &[step | &1])
  end

  @spec concat(t, [Pipeline.Step.t]) :: t
  def concat(pipeline, phases) do
    update_in(pipeline.phases, &(&1 ++ phases))
  end

  @spec done :: t
  def done do
    %__MODULE__{phases: []}
  end

end
