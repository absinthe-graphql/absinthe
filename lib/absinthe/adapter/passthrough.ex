defmodule Absinthe.Adapter.Passthrough do
  @moduledoc """
  The default adapter, which makes no changes to incoming query document
  ASTs or outgoing results.
  """

  use Absinthe.Adapter

  def load_document(doc), do: doc

  def dump_results(results), do: results
end
