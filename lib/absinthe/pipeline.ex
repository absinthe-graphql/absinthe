defmodule Absinthe.Pipeline do

  alias Absinthe.Phase

  @type input_t :: any
  @type output_t :: any
  @type phase_config_t :: Phase.t | {Phase.t, any}

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
    Enum.reduce_while(pipeline, input, fn config, item ->
      {phase, args} = phase_invocation(config, item)
      case apply(phase, :run, args) do
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
    end)
  end

  @spec phase_invocation(phase_config_t, input_t) :: {Phase.t, list}
  defp phase_invocation({phase, args}, item) do
    {phase, [item | [args]]}
  end
  defp phase_invocation(phase, item) do
    {phase, [item]}
  end

  @spec for_operation :: t
  def for_operation do
    [
      Phase.Parse,
      Phase.Blueprint,
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
