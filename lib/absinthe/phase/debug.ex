defmodule Absinthe.Phase.Debug do
  use Absinthe.Phase

  alias Absinthe.Blueprint

  @spec run(any) :: {:ok, Blueprint.t}
  def run(input) do
    IO.inspect(input)
    {:ok, input}
  end

end
