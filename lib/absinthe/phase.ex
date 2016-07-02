defmodule Absinthe.Phase do
  @type t :: module

  alias __MODULE__

  defmacro __using__(_) do
    quote do
      @behaviour Phase
    end
  end

  @callback run(any) :: {:ok, any} | {:error, Phase.Error.t}

end
