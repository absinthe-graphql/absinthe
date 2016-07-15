defmodule Absinthe.Phase do

  @type t :: module
  @type result_t :: {:cont | :halt, any}

  alias __MODULE__

  defmacro __using__(_) do
    quote do
      @behaviour Phase

      def run(input, options), do: {:ok, input}

      def check_input(_), do: :ok
      defoverridable check_input: 1, run: 2
    end
  end

  @callback run(any, any) :: {:ok, any} | {:error, Phase.Error.t}
  @callback check_input(any) :: :ok | {:error, Phase.Error.t}

end
