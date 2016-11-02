defmodule Absinthe.Blueprint.Document.Resolution.PluginInvocation do

  @moduledoc false

  defstruct [
    :plugin_module,
    :data,
    :emitter,
    :info,
    :source,
  ]

  def init(plugin_module, data, acc, blueprint, info, source) do
    {data, acc} = plugin_module.init(data, acc)

    invocation = %__MODULE__{
      plugin_module: plugin_module,
      data: data,
      source: source,
      emitter: blueprint,
      info: info,
    }
    {invocation, acc}
  end

  def resolve(%{plugin_module: plugin_module, data: data}, acc) do
    plugin_module.resolve(data, acc)
  end
end
