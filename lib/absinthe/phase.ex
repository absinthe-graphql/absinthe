defmodule Absinthe.Phase do

  @type t :: module
  @type result_t :: {:cont | :halt, any}

  alias __MODULE__

  defmacro __using__(_) do
    quote do
      @behaviour Phase

      def run(input), do: {:ok, input}

      defoverridable run: 1
    end
  end

  @callback run(any) :: {:ok, any} | {:error, Phase.Error.t}

end
