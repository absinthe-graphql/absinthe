defmodule Absinthe.Pipeline do

  alias Absinthe.Phase

  @type input_t :: any
  @type output_t :: any
  @type phase_config_t :: Phase.t | {Phase.t, Keyword.t}

  @type t :: [phase_config_t]

  @spec run(input_t, t) :: {:ok, output_t} | {:error, Phase.Error.t}
  def run(input, pipeline) do
    case do_run(input, pipeline) do
      {:error, _} = err ->
        err
      result ->
        {:ok, result}
    end
  end

  @bad_return "Phase did not return an {:ok, any} | {:error, Absinthe.Phase.Error.t} | {:error, String.t}"

  @spec do_run(input_t, t) :: {:ok, output_t} | {:error, Phase.Error.t}
  defp do_run(input, pipeline) do
    Enum.reduce_while(pipeline, input, fn config, input ->
      {phase, options} = phase_invocation(config)
      with :ok <- check_input(phase, input) do
        run_phase(phase, input, options)
      end
    end)
  end

  defp check_input(phase, input) do
    case phase.check_input(input) do
      :ok ->
        :ok
      {:error, message} ->
        {:halt, {:error, %Phase.Error{phase: phase, message: message}}}
    end
  end

  defp run_phase(phase, input, options) do
    case phase.run(input, options) do
      {:ok, result} ->
        {:cont, result}
      {:error, %Phase.Error{}} = err ->
        {:halt, err}
      {:error, message} ->
        err = {:error, %Phase.Error{message: message, phase: phase}}
        {:halt, err}
      _ ->
        err = {:error, %Phase.Error{message: @bad_return, phase: phase}}
        {:halt, err}
    end
  end

  @spec phase_invocation(phase_config_t) :: {Phase.t, list}
  defp phase_invocation({phase, options}) do
    {phase, options}
  end
  defp phase_invocation(phase) do
    {phase, []}
  end

  @spec for_document :: t
  @spec for_document(map) :: t
  def for_document(provided_values \\ %{}) do
    [
      Phase.Parse,
      Phase.Blueprint,
      {Phase.Document.Variables, values: provided_values},
      Phase.Document.Arguments,
      # TODO: More
    ]
  end

  @spec for_schema :: t
  def for_schema do
    [
      Phase.Parse,
      Phase.Blueprint,
      # TODO: More
    ]
  end

end
