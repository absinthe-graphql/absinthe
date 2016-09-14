defmodule Absinthe.Phase.Debug do
  use Absinthe.Phase

  alias Absinthe.Blueprint

  @spec run(any) :: {:ok, Blueprint.t}
  def run(input) do
    if System.get_env("DEBUG") do
      IO.inspect(input)
    end
    {:ok, input}
  end

end
