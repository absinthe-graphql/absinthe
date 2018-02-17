defmodule Harness.Document.Phase do

  alias Absinthe.{Phase, Pipeline}

  defmacro __using__(opts) do
    phase = Keyword.fetch!(opts, :phase)
    schema = Keyword.fetch!(opts, :schema)
    quote do
      @doc """
      Execute the pipeline up to and through a phase.
      """
      @spec run_phase(String.t, Keyword.t) :: Phase.result_t
      def run_phase(query, options) do
        options =
          options
          |> Keyword.put(:jump_phases, false)
          |> Keyword.put_new(:analyze_complexity, true)
        pipeline = Pipeline.for_document(unquote(schema), options)
        Pipeline.run(query, pipeline |> Pipeline.upto(unquote(phase)))
      end
    end
  end

end
