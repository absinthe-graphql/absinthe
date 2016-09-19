defmodule Harness.Document.Phase do

  alias Absinthe.{Phase, Pipeline}

  defmacro __using__(opts) do
    phase = Keyword.fetch!(opts, :phase)
    schema = Keyword.fetch!(opts, :schema)
    quote do
      @doc """
      Execute the pipeline up to and through a phase.
      """
      @spec run_phase(String.t, map) :: Phase.result_t
      @spec run_phase(String.t, map, [any]) :: Phase.result_t
      def run_phase(query, provided_values, additional_args \\ []) do
        pipeline = Pipeline.for_document(unquote(schema), provided_values)
        |> Pipeline.before(unquote(phase))
        with {:ok, blueprint, _} <- Pipeline.run(query, pipeline) do
          apply(unquote(phase), :run, [blueprint | additional_args])
        end
      end
    end
  end

end
