defmodule Absinthe.Resolution.Helpers do
  @moduledoc """
  Some handy functions for returning async or batched resolution functions

  Generally used via `import #{__MODULE__}`
  """

  @doc """
  Execute resolution field asynchronously.

  Forbidden in mutation fields.
  """
  def async(fun) do
    async = %Absinthe.Resolution.Plugin.Async{
      task: Task.async(fun)
    }
    {:plugin, async}
  end
end
