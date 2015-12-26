defmodule Absinthe.Type.Definitions do

  alias Absinthe.Type

  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__)
      Module.register_attribute(__MODULE__, :absinthe_types, accumulate: true)
      @on_definition unquote(__MODULE__)
      @before_compile unquote(__MODULE__)
    end
  end

  def __on_definition__(env, kind, name, args, guards, body) do
    absinthe_attr = Module.get_attribute(env.module, :absinthe)
    Module.put_attribute(env.module, :absinthe, nil)
    if absinthe_attr do
      case {kind, absinthe_attr} do
        {:def, :type} ->
          Module.put_attribute(env.module, :absinthe_types, {name, name})
        {:def, [{:type, identifier}]} ->
          Module.put_attribute(env.module, :absinthe_types, {identifier, name})
        {:defp, _} -> raise  "Absinthe type definition #{name} must be a def, not defp"
        _ -> raise "Unknown absinthe definition for #{name}"
      end
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def absinthe_types do
        @absinthe_types
        |> Enum.into(%{}, fn {identifier, fn_name} ->
          ready = apply(__MODULE__, fn_name, [])
          |> Absinthe.Type.Definitions.set_default_name(identifier)
          tagged = %{ready | reference: %Absinthe.Type.Reference{module: __MODULE__, identifier: identifier, name: ready.name}}
          {identifier, tagged}
        end)
      end
    end
  end

  @doc """
  Add a name field to a type (using the absinthe type identifier)
  unless it's already been defined.
  """
  @spec set_default_name(Type.t, atom) :: Type.t
  def set_default_name(%{name: nil} = type, identifier) do
    %{type | name: identifier |> to_string |> Macro.camelize}
  end
  def set_default_name(%{name: _} = type, _identifier) do
    type
  end

  defmacro fields(definitions) do
    quote do
      fn ->
        named(Absinthe.Type.FieldDefinition, unquote(definitions))
      end
    end
  end


  @doc """
  Deprecate a field or argument with an optional reason
  """
  @spec deprecate(Keyword.t) :: Keyword.t
  @spec deprecate(Keyword.t, Keyword.t) :: Keyword.t
  def deprecate(node, options \\ []) do
    node
    |> Keyword.put(:deprecation, struct(Type.Deprecation, options))
  end

  def non_null(type) do
    %Type.NonNull{of_type: type}
  end

  def list_of(type) do
    %Type.List{of_type: type}
  end

  def args(definitions) do
    named(Absinthe.Type.Argument, definitions)
  end

  def named(mod, definitions) do
    definitions
    |> Enum.into(%{}, fn ({identifier, definition}) ->
      {
        identifier,
        struct(mod, [{:name, identifier |> to_string} | definition])
      }
    end)
  end

end
