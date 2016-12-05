# TODO: This will become Absinthe.Schema.Notation before release
defmodule Absinthe.Schema.Notation.Blueprint do

  alias Absinthe.Blueprint

  def add(blueprint, {:type, scope}, %Blueprint.Schema.FieldDefinition{} = field) do
    types = Enum.map(blueprint.types, fn
      %{identifier: ^scope} = type ->
        %{type | fields: [field | type.fields]}
      other ->
        other
    end)
    %{blueprint | types: types}
  end
  def add(blueprint, nil, type) do
    %{blueprint | types: [type | blueprint.types]}
  end

  defmacro __using__(_opts) do
    quote do
      @absinthe_blueprint %Absinthe.Blueprint{}
      @absinthe_scope nil
      import unquote(__MODULE__), only: :macros
      @before_compile unquote(__MODULE__)
    end
  end

  defmacro object(identifier, do: body) do
    name = identifier |> Atom.to_string |> Absinthe.Utils.camelize
    [
      quote do
        item = %Absinthe.Blueprint.Schema.ObjectTypeDefinition{
          name: unquote(name),
          identifier: unquote(identifier)
        }
        @absinthe_scope nil
        @absinthe_blueprint unquote(__MODULE__).add(@absinthe_blueprint, @absinthe_scope, item)
        @absinthe_scope {:type, unquote(identifier)}
      end,
      body
    ]
  end

  defmacro field(identifier, type, do: body) do
    name = identifier |> Atom.to_string |> Absinthe.Utils.camelize(lower: true)
    [
      quote do
        item = %Absinthe.Blueprint.Schema.FieldDefinition{name: unquote(name), identifier: unquote(identifier), type: unquote(type)}
        @absinthe_blueprint unquote(__MODULE__).add(@absinthe_blueprint, @absinthe_scope, item)
        @absinthe_scope {:field, @absinthe_scope, unquote(identifier)}
      end,
      body
    ]
  end

  defmacro __before_compile__(env) do
    quote do
      def __absinthe_blueprint__ do
        @absinthe_blueprint
      end
    end
  end

end
