defmodule Absinthe.Pipeline do

  alias Absinthe.{Phase}

  @type t :: [Phase.t]

  @spec run(any, t) :: {:ok, any} | {:error, Phase.Error.t}
  def run(input, pipeline) do
    case do_run(input, pipeline) do
      {:error, _} = err ->
        err
      result ->
        {:ok, result}
    end
  end

  defp do_run(input, pipeline) do
    Enum.reduce_while(pipeline, input, fn phase, item ->
      case phase.run(item) do
        {:ok, result} ->
          {:cont, result}
        {:error, %Phase.Error{}} = err ->
          {:halt, err}
        {:error, message} ->
          err = {:error, %Phase.Error{message: message, phase: phase}}
          {:halt, err}
      end
    end)
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
