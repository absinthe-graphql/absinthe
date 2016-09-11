defmodule Absinthe.Case.Run do

  def run(document, schema, options \\ []) do
    pipeline = Absinthe.Pipeline.for_document(schema, Map.new(options))
    pipeline = if System.get_env("DEBUG") do
      pipeline
      |> Absinthe.Pipeline.insert_before(
        Absinthe.Phase.Document.Execution.Resolution,
        Absinthe.Phase.Debug
      )
    else
      pipeline
    end
    Absinthe.Pipeline.run(document, pipeline)
  end

end
