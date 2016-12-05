# TODO: This will become Absinthe.Schema.Notation before release
defmodule Absinthe.Schema.Notation.Experimental do

  alias Absinthe.Blueprint

  @typep scope_t :: {:type, atom} | {:field, {:type, atom}, atom}

  @spec lookup_type(Blueprint.t, atom) :: nil | Blueprint.Schema.type_t
  @doc false
  def lookup_type(blueprint, identifier) do
    Enum.find(blueprint.types, fn
      %{identifier: ^identifier} ->
        true
      _ ->
        false
    end)
  end

  @spec update_type(Blueprint.t, atom, (Blueprint.Schema.type_t -> Blueprint.Schema.type_t)) :: Blueprint.t
  @doc false
  def update_type(blueprint, identifier, fun) do
    update_in(blueprint, [Access.key(:types), Access.all()], fn
      %{identifier: ^identifier} = type ->
        fun.(type)
      other ->
        other
    end)
  end

  @spec put_type(Blueprint.t, Blueprint.Schema.type_t) :: Blueprint.t
  @doc false
  def put_type(blueprint, type) do
    update_in(blueprint.types, &[type | &1])
  end

  @spec put_field(Blueprint.t, scope_t, Blueprint.Schema.FieldDefinition.t) :: Blueprint.t
  @doc false
  def put_field(blueprint, {:type, identifier}, %Blueprint.Schema.FieldDefinition{} = field) do
    update_type(blueprint, identifier, fn
      type ->
        update_in(type.fields, &[field | &1])
    end)
  end

  @spec put_attrs(Blueprint.t, scope_t, Keyword.t) :: Blueprint.t
  @doc false
  def put_attrs(blueprint, {:type, type_identifier}, attrs) do
    update_type(blueprint, type_identifier, &struct(&1, attrs))
  end
  def put_attrs(blueprint, {:field, {:type, type_identifier}, field_identifier}, attrs) do
    update_type(blueprint, type_identifier, fn
      type ->
        update_in(type, [Access.key(:fields), Access.all()], fn
          %{identifier: ^field_identifier} = field ->
            struct(field, attrs)
          other ->
            other
        end)
    end)
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
        @absinthe_blueprint unquote(__MODULE__).put_type(
          @absinthe_blueprint,
          %Absinthe.Blueprint.Schema.ObjectTypeDefinition{
            name: unquote(name),
            identifier: unquote(identifier)
          }
        )
        @absinthe_scope {:type, unquote(identifier)}
      end,
      body
    ]
  end

  defmacro field(identifier, type, do: body) do
    name = identifier |> Atom.to_string |> Absinthe.Utils.camelize(lower: true)
    [
      quote do
        @absinthe_blueprint unquote(__MODULE__).put_field(
          @absinthe_blueprint,
          @absinthe_scope,
          %Absinthe.Blueprint.Schema.FieldDefinition{
            name: unquote(name),
            identifier: unquote(identifier),
            type: unquote(type)
          }
        )
        @absinthe_scope {:field, @absinthe_scope, unquote(identifier)}
      end,
      body
    ]
  end

  defmacro resolve(fun) do
    quote do
      @absinthe_blueprint unquote(__MODULE__).put_attrs(
        @absinthe_blueprint,
        @absinthe_scope,
        resolve_ast: unquote(Macro.escape(fun))
      )
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def __absinthe_blueprint__ do
        @absinthe_blueprint
      end
    end
  end

end
