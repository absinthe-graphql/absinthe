defmodule Absinthe.Schema.Notation.Scope do
  @moduledoc false

  @stack :absinthe_notation_scopes

  defstruct name: nil, recordings: [], attrs: []

  use Absinthe.Type.Fetch

  def open(name, mod, attrs \\ []) do
    Module.put_attribute(mod, @stack, [%__MODULE__{name: name, attrs: attrs} | on(mod)])
  end

  def close(mod) do
    {current, rest} = split(mod)
    Module.put_attribute(mod, @stack, rest)
    current
  end

  def split(mod) do
    case on(mod) do
      [] ->
        {nil, []}

      [current | rest] ->
        {current, rest}
    end
  end

  def current(mod) do
    {c, _} = split(mod)
    c
  end

  def recorded!(mod, kind, identifier) do
    update_current(mod, fn
      %{recordings: recs} = scope ->
        %{scope | recordings: [{kind, identifier} | recs]}

      nil ->
        # Outside any scopes, ignore
        nil
    end)
  end

  @doc """
  Check if a certain operation has been recorded in the current scope.

  ## Examples

  See if an input object with the identifier `:input` has been defined from
  this scope:

  ```
  recorded?(mod, :input_object, :input)
  ```

  See if the `:description` attribute has been

  ```
  recorded?(mod, :attr, :description)
  ```
  """
  @spec recorded?(atom, atom, atom) :: boolean
  def recorded?(mod, kind, identifier) do
    scope = current(mod)

    case kind do
      :attr ->
        # Supports attributes passed directly to the macro that
        # created the scope, usually (?) short-circuits the need to
        # check the scope recordings.
        scope.attrs[identifier] || recording_marked?(scope, kind, identifier)

      _ ->
        recording_marked?(scope, kind, identifier)
    end
  end

  # Check the list of recordings for `recorded?/3`
  defp recording_marked?(scope, kind, identifier) do
    scope.recordings
    |> Enum.find(fn
      {^kind, ^identifier} ->
        true

      _ ->
        false
    end)
  end

  def put_attribute(mod, key, value, opts \\ [accumulate: false]) do
    if opts[:accumulate] do
      update_current(mod, fn scope ->
        new_attrs = update_in(scope.attrs, [key], &[value | &1 || []])
        %{scope | attrs: new_attrs}
      end)
    else
      update_current(mod, fn scope ->
        %{scope | attrs: Keyword.put(scope.attrs, key, value)}
      end)
    end
  end

  defp update_current(mod, fun) do
    {current, rest} = split(mod)
    updated = fun.(current)
    Module.put_attribute(mod, @stack, [updated | rest])
  end

  def on(mod) do
    case Module.get_attribute(mod, @stack) do
      nil ->
        Module.put_attribute(mod, @stack, [])
        []

      value ->
        value
    end
  end
end
