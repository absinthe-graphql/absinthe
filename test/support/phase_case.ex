defmodule Absinthe.PhaseCase do
  defmacro __using__(opts) do
    phase = Keyword.fetch!(opts, :phase)
    schema = Keyword.fetch!(opts, :schema)

    quote do
      @doc """
      Execute the pipeline up to and through a phase.
      """

      use Absinthe.Case, unquote(opts)

      @spec run_phase(String.t(), Keyword.t()) :: Absinthe.Phase.result_t()
      def run_phase(query, options) do
        options =
          options
          |> Keyword.put(:jump_phases, false)
          |> Keyword.put_new(:analyze_complexity, true)

        pipeline = Absinthe.Pipeline.for_document(unquote(schema), options)
        Absinthe.Pipeline.run(query, pipeline |> Absinthe.Pipeline.upto(unquote(phase)))
      end
    end
  end
end
