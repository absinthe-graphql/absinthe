defmodule Absinthe.Schema.Manager do
  use GenServer

  def start_link(schema) do
    GenServer.start_link(__MODULE__, schema, [])
  end

  def init(_schema_module) do
    :ignore
  end
end
