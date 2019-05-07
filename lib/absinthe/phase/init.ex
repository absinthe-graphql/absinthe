defmodule Absinthe.Phase.Init do
  @moduledoc false

  use Absinthe.Phase

  alias Absinthe.{Blueprint, Language, Phase}

  @spec run(Language.Source.t(), Keyword.t()) :: Phase.result_t()
  def run(input, _options \\ []) do
    {:ok, %Blueprint{input: input}}
  end
end
