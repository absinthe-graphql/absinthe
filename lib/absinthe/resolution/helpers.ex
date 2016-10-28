defmodule Absinthe.Resolution.Helpers do
  @moduledoc """
  Handy functions for returning async or batched resolution functions

  It is automatically imported into all modules using `Absinthe.Schema.Notation`
  or (by extension) `Absinthe.Schema`.
  """

  @doc """
  Execute resolution field asynchronously.

  This is a helper function for using the `Absinthe.Resolution.Plugin.Async`.

  Forbidden in mutation fields. (TODO: actually enforce this)
  """
  def async(fun) do
    {:plugin, Absinthe.Resolution.Plugin.Async, Task.async(fun)}
  end
end
