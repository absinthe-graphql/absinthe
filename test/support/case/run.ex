defmodule Absinthe.Case.Run do

  def run(document, schema, options \\ []) do
    pipeline = Absinthe.Pipeline.for_document(schema, Map.new(options))
    Absinthe.Pipeline.run(document, pipeline)
  end

end
