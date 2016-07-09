defmodule Absinthe.Phase do
  @type t :: module

  alias __MODULE__

  defmacro __using__(_) do
    quote do
      @behaviour Phase

      def run(input, options), do: {:ok, input}

      def check_input(_), do: :ok
      defoverridable check_input: 1, run: 2
    end
  end

  @callback run(any, Keyword.t) :: {:ok, any} | {:error, Phase.Error.t}
  @callback check_input(any) :: :ok | {:error, Phase.Error.t}

end
