defmodule Absinthe.Pipeline do

  alias Absinthe.Phase
  alias __MODULE__

  @type input_t :: any
  @type output_t :: %{errors: [Phase.Error.t]}

  @type phase_config_t :: Phase.t | {Phase.t, [any]}

  @type t :: [phase_config_t | [phase_config_t]]

  @spec run(input_t, t) :: {:ok, output_t} | {:error, String.t}
  def run(input, pipeline) do
    case do_run(input, pipeline) do
      {:ok, _} = halted_with_user_errors ->
        halted_with_user_errors
      {:error, _} = halted_with_developer_errors ->
        halted_with_developer_errors
      completed ->
        {:ok, completed}
    end
  end

  @spec for_document(Absinthe.Schema.t) :: t
  @spec for_document(Absinthe.Schema.t, map) :: t
  def for_document(schema, provided_values \\ %{}) do
    [
      Phase.Parse,
      Phase.Blueprint,
      Phase.Document.Validation.structural,
      {Phase.Document.Variables, provided_values},
      Phase.Document.Arguments,
      {Phase.Document.Schema, schema},
      Phase.Document.Directives,
      Phase.Document.Flatten,
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

  @bad_return "Phase did not return an {:ok, any} | {:error, %{errors: [Phase.Error.t]} | Phase.Error.t | String.t} tuple"

  @spec do_run(input_t, t) :: {:ok, output_t} | {:error, Phase.Error.t}
  defp do_run(input, pipeline) do
    List.flatten(pipeline)
    |> Enum.reduce_while(input, fn config, input ->
      {phase, args} = phase_invocation(config)
      case apply(phase, :run, [input | args]) do
        {:ok, value} ->
          {:cont, value}
        {:error, value} when is_binary(value) ->
          halt_with_error_result(phase, value)
        {:error, %Phase.Error{} = value} ->
          halt_with_error_result(phase, value)
        {:error, %{errors: _} = value} ->
          halt_with_error_result(phase, value)
        {:pipeline_error, message} ->
          {:halt, {:error, message}}
        _ ->
          {:halt, {:error, phase_error(phase, @bad_return)}}
      end
    end)
  end

  @spec halt_with_error_result(Phase.t, output_t | Phase.Error.t | [Phase.Error.t]) :: {:halt, {:ok, output_t}}
  defp halt_with_error_result(phase, error) do
    {:halt, {:ok, result_with_errors(phase, error)}}
  end

  @spec phase_invocation(phase_config_t) :: {Phase.t, list}
  defp phase_invocation({phase, args}) do
    {phase, List.wrap(args)}
  end
  defp phase_invocation(phase) do
    {phase, []}
  end

  @spec result_with_errors(Phase.t, output_t | Phase.Error.t | [Phase.Error.t]) :: output_t
  defp result_with_errors(_, %{errors: _} = result) do
    result
  end
  defp result_with_errors(phase, err) do
    Pipeline.ErrorResult.new(phase_error(phase, err))
  end

  @spec phase_error(Phase.t, Phase.Error.t | String.t) :: Phase.Error.t
  defp phase_error(_, %Phase.Error{} = err) do
    err
  end
  defp phase_error(phase, message) when is_binary(message) do
    %Phase.Error{
      message: message,
      phase: phase,
    }
  end

end
