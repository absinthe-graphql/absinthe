defmodule Absinthe.Case.Helpers.Run do
  def run(document, schema, options \\ []) do
    Absinthe.run(document, schema, options)
  end
end
