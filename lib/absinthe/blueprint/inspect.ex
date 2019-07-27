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

defimpl Inspect, for: Absinthe.Blueprint.Schema.InterfaceTypeDefinition do
  def inspect(term, %{pretty: true}) do
    Absinthe.Schema.Notation.SDL.Render.inspect(term)
  end

  def inspect(term, options) do
    Inspect.Any.inspect(term, options)
  end
end

defimpl Inspect, for: Absinthe.Blueprint.Schema.InputObjectTypeDefinition do
  def inspect(term, %{pretty: true}) do
    Absinthe.Schema.Notation.SDL.Render.inspect(term)
  end

  def inspect(term, options) do
    Inspect.Any.inspect(term, options)
  end
end

defimpl Inspect, for: Absinthe.Blueprint.Schema.UnionTypeDefinition do
  def inspect(term, %{pretty: true}) do
    Absinthe.Schema.Notation.SDL.Render.inspect(term)
  end

  def inspect(term, options) do
    Inspect.Any.inspect(term, options)
  end
end

defimpl Inspect, for: Absinthe.Blueprint.Schema.SchemaDeclaration do
  def inspect(term, %{pretty: true}) do
    Absinthe.Schema.Notation.SDL.Render.inspect(term)
  end

  def inspect(term, options) do
    Inspect.Any.inspect(term, options)
  end
end

defimpl Inspect, for: Absinthe.Blueprint.Schema.ScalarTypeDefinition do
  def inspect(term, %{pretty: true}) do
    Absinthe.Schema.Notation.SDL.Render.inspect(term)
  end

  def inspect(term, options) do
    Inspect.Any.inspect(term, options)
  end
end

defimpl Inspect, for: Absinthe.Blueprint.Schema.DirectiveDefinition do
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
