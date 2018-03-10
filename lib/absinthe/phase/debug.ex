defmodule Absinthe.Phase.Debug do
  use Absinthe.Phase

  @moduledoc false

  alias Absinthe.Blueprint

  @spec run(any, Keyword.t()) :: {:ok, Blueprint.t()}
  def run(input, _options \\ []) do
    if System.get_env("DEBUG") do
      IO.inspect(input)
    end

    {:ok, input}
  end
end
