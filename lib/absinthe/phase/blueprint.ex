defmodule Absinthe.Phase.Blueprint do
  use Absinthe.Phase

  alias Absinthe.{Blueprint, Language, Pipeline}

  @spec run(Language.Document.t, Pipeline.t) :: {:ok, Blueprint.t, Pipeline.t}
  def run(input, pipeline) do
    blueprint = Blueprint.from_ast(input)
    {:ok, blueprint, pipeline_for_purpose(blueprint, pipeline)}
  end

  # TODO: Make these phases actually exist
  defp pipeline_for_purpose(%Blueprint{purpose: :operation}, pipeline) do
    Pipeline.concat(pipeline, [Phase.Operation.Parameterize, Phase.ExpandDirectives, Phase.Operation.Execute])
  end
  defp pipeline_for_purpose(%Blueprint{purpose: :schema}, pipeline) do
    Pipeline.concat(pipeline, [Phase.ExpandDirectives, Phase.Schema.Materialize])
  end
  defp pipeline_for_purpose(_, pipeline) do
    pipeline
  end

end
