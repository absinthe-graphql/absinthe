defmodule Absinthe.Sigil do
  @moduledoc """
  Provides the ~GQL sigil
  """

  def sigil_GQL(string, []) do
    case Absinthe.Phase.Parse.run(string, []) do
      {:ok, blueprint} ->
        inspect(blueprint.input, pretty: true)

      {:error, %Absinthe.Blueprint{execution: %{validation_errors: [_ | _] = errors}}} ->
        {:current_stacktrace, [_process_info, _absinthe_sigil, {_, _, _, loc} | _]} =
          Process.info(self(), :current_stacktrace)

        err_string =
          Enum.join(
            [
              "~GQL sigil validation error at " <> inspect(loc)
              | Enum.map(errors, &"#{&1.message} (#{inspect(&1.locations)})")
            ],
            "\n"
          )

        IO.puts(:stderr, err_string)
        string
    end
  end
end
