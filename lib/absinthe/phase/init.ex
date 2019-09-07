defmodule Absinthe.Phase.Init do
  @moduledoc false

  use Absinthe.Phase

  alias Absinthe.{Blueprint, Language, Phase}

  @spec run(String.t() | Language.Source.t() | Blueprint.t(), Keyword.t()) :: Phase.result_t()
  def run(input, _options \\ []) do
    {:record_phases, make_blueprint(input),
     fn bp, phases ->
       %{bp | initial_phases: phases}
     end}
  end

  defp make_blueprint(%Absinthe.Blueprint{} = blueprint) do
    blueprint
  end

  defp make_blueprint(input) do
    %Blueprint{input: input}
  end
end
