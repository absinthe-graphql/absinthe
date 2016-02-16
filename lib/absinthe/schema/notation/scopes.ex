defmodule Absinthe.Schema.Notation.Scopes do

  @stack :absinthe_notation_scopes

  def open(mod, attrs \\ []) do
    Module.put_attribute(mod, @stack, [attrs | stack(mod)])
  end

  def close(mod) do
    {current, rest} = split(mod)
    Module.put_attribute(mod, @stack, rest)
    current
  end

  def split(mod) do
    [scope | rest] = stack(mod)
    {scope, rest}
  end

  def put_attribute(mod, key, value, opts \\ [accumulate: false]) do
    if Keyword.get(opts, :accumulate) do
      update_current(mod, fn
        scope ->
          update_in(scope, [key], &[value | (&1 || [])])
      end)
    else
      update_current(mod, fn
        scope ->
          Keyword.put(scope, key, value)
      end)
    end
  end

  defp update_current(mod, fun) do
    {current, rest} = split(mod)
    updated = fun.(current)
    Module.put_attribute(mod, @stack, [updated | rest])
  end

  defp stack(mod) do
    case Module.get_attribute(mod, @stack) do
      nil ->
        Module.put_attribute(mod, @stack, [])
        []
      value ->
        value
    end
  end

end
