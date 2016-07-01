defmodule Absinthe.Phase.Blueprint do
  use Absinthe.Phase

  alias Absinthe.{Blueprint, Language}

  @spec run(Language.Document.t) :: {:ok, Blueprint.t}
  def run(input) do
    {:ok, Blueprint.from_ast(input)}
  end

end
