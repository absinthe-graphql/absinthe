defmodule Absinthe.Phase.Debug do
  use Absinthe.Phase

  @moduledoc false

  require Logger

  @spec run(any, Keyword.t()) :: {:ok, Absinthe.Blueprint.t()}
  def run(input, _options \\ []) do
    Logger.debug("[Absinthe Blueprint]", input)
    {:ok, input}
  end
end
