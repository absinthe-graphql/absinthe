defmodule Absinthe.Phase.Init do
  @moduledoc false

  use Absinthe.Phase

  alias Absinthe.{Blueprint, Language, Phase}

  @spec run(String.t() | Language.Source.t() | Blueprint.t(), Keyword.t()) :: Phase.result_t()
  def run(blueprint, options \\ [])

  def run(%Absinthe.Blueprint{} = blueprint, _options) do
    {:ok, blueprint}
  end

  def run(input, _options) do
    {:ok, %Blueprint{input: input}}
  end
end
