defimpl Inspect, for: Absinthe.Blueprint do
  def inspect(term, %{pretty: true}) do
    Absinthe.Schema.Notation.SDL.Render.inspect(term)
  end

  def inspect(term, options) do
    Inspect.Any.inspect(term, options)
  end
end

defimpl Inspect, for: Absinthe.Blueprint.Schema.ObjectTypeDefinition do
  def inspect(term, %{pretty: true}) do
    Absinthe.Schema.Notation.SDL.Render.inspect(term)
  end

  def inspect(term, options) do
    Inspect.Any.inspect(term, options)
  end
end

defimpl Inspect, for: Absinthe.Blueprint.Schema.EnumTypeDefinition do
  def inspect(term, %{pretty: true}) do
    Absinthe.Schema.Notation.SDL.Render.inspect(term)
  end

  def inspect(term, options) do
    Inspect.Any.inspect(term, options)
  end
end

# TODO: ^^ for all renderable Absinthe.Blueprint.Schema.*
