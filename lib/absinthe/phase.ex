defmodule Absinthe.Phase do
  @type t :: module

  defmacro __using__(_) do
    quote do
      @behaviour Absinthe.Phase
    end
  end

  @callback run(any, Absinthe.Pipeline.t) :: {:ok, any, Absinthe.Pipeline.t} | {:error, Absinthe.Error.t}

end
