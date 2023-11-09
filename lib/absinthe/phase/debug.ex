defmodule Absinthe.Phase.Debug do
  use Absinthe.Phase

  @moduledoc false

  require Logger
  alias Absinthe.Blueprint

  @spec run(any, Keyword.t()) :: {:ok, Blueprint.t()}
  def run(input, _options \\ []) do
    if System.get_env("DEBUG") do
      Logger.info(input)
    end

    {:ok, input}
  end
end
