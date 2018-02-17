# TODO: This will become Absinthe.Schema.Notatigon before release
defmodule Absinthe.Schema.Notation.Experimental do

  alias Absinthe.Blueprint

  @typep scope_t :: {:type, atom} | {:field, {:type, atom}, atom}

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

  @spec concat_types(Blueprint.t, Blueprint.t, Keyword.t) :: Blueprint.t
  def concat_types(blueprint, other, opts) do
    selected = select_import(other.types, Map.new(opts))
    update_in(blueprint.types, &(selected ++ &1))
  end

  defp select_import(collection, %{only: ids}) when is_list(ids) do
    Enum.filter(collection, &(&1.identifier in ids))
  end
  defp select_import(collection, %{except: ids}) when is_list(ids) do
    collection -- select_import(collection, %{only: ids})
  end
  defp select_import(collection, opts) when map_size(opts) == 0 do
    collection
  end

  def concat_fields(blueprint, {:type, _} = scope, {mod, source_type_identifier} = criteria, opts) do
    Blueprint.Schema.lookup_type(mod.__absinthe_blueprint__(), source_type_identifier)
    |> do_concat_fields(blueprint, scope, criteria, opts)
  end
  def concat_fields(blueprint, {:type, _} = scope, source_type_identifier = criteria, opts) when is_atom(source_type_identifier) do
    Blueprint.Schema.lookup_type(blueprint, source_type_identifier)
    |> do_concat_fields(blueprint, scope, criteria, opts)
  end

  defp do_concat_fields(%{fields: fields}, blueprint, scope, _criteria, opts) do
    selected = select_import(fields, Map.new(opts))
    Enum.reduce(selected, blueprint, &put_field(&2, scope, &1))
  end
  defp do_concat_fields(_, _, _, criteria, _) do
    raise "Not a valid source for fields: #{inspect(criteria)}"
  end

  defp push_scope(scope) do
    quote do: @absinthe_scopes [unquote(scope) | @absinthe_scopes]
  end
  defp pop_scope do
    quote do: @absinthe_scopes tl(@absinthe_scopes)
  end
  defp scoped(body, scope) do
    [
      push_scope(scope),
      body,
      pop_scope()
    ]
  end

  defmacro __using__(_opts) do
    quote do
      @absinthe_blueprint %Absinthe.Blueprint{}
      @absinthe_scopes []
      @desc nil
      import unquote(__MODULE__), only: :macros
      @before_compile unquote(__MODULE__)
    end
  end

  defmacro query(do: body) do
    object_definition(:query, [name: "RootQueryType"], body)
  end
  defmacro query(attrs, do: body) when is_list(attrs) do
    object_definition(:query, attrs, body)
  end

  defmacro mutation(do: body) do
    object_definition(:mutation, [name: "RootMutationType"], body)
  end
  defmacro mutation(attrs, do: body) when is_list(attrs) do
    object_definition(:mutation, attrs, body)
  end

  defmacro subscription(do: body) do
    object_definition(:subscription, [name: "RootSubscriptionType"], body)
  end
  defmacro subscription(attrs, do: body) when is_list(attrs) do
    object_definition(:subscription, attrs, body)
  end

  defmacro object(identifier, do: body) do
    object_definition(identifier, [], body)
  end

  defmacro object(identifier, attrs, do: body) do
    object_definition(identifier, attrs, body)
  end

  def object_definition(identifier, attrs, body) do
    {desc, attrs} =
      attrs
      |> Keyword.put_new(:name, default_object_name(identifier))
      |> Keyword.pop(:description)

    [
      quote do
        @absinthe_blueprint unquote(__MODULE__).put_type(
          @absinthe_blueprint,
          %Absinthe.Blueprint.Schema.ObjectTypeDefinition{
            unquote_splicing(attrs),
            description: @desc || unquote(desc),
            identifier: unquote(identifier)
          }
        )
        @desc nil
      end,
      body |> scoped({:type, identifier}),
    ]
  end

  defp default_object_name(identifier) do
    identifier
    |> Atom.to_string
    |> Absinthe.Utils.camelize
  end

  @spec import_types(atom) :: Macro.t
  defmacro import_types(module, opts \\ []) do
    quote do
      @absinthe_blueprint unquote(__MODULE__).concat_types(
        @absinthe_blueprint,
        unquote(module).__absinthe_blueprint__(),
        unquote(opts)
      )
    end
  end

  @spec import_fields(atom | {module, atom}, Keyword.t) :: Macro.t
  defmacro import_fields(source_criteria, opts \\ []) do
    quote do
      @absinthe_blueprint unquote(__MODULE__).concat_fields(
        @absinthe_blueprint,
        hd(@absinthe_scopes),
        unquote(source_criteria),
        unquote(opts)
      )
    end
  end

  @spec field(atom, atom | Keyword.t) :: Macro.t
  defmacro field(identifier, attrs) when is_list(attrs) do
    field_definition(identifier, attrs, nil)
  end
  defmacro field(identifier, type) when is_atom(type) do
    field_definition(identifier, [type: type], nil)
  end

  @spec field(atom, atom | Keyword.t, [do: Macro.t]) :: Macro.t
  defmacro field(identifier, attrs, do: body) when is_list(attrs) do
    field_definition(identifier, attrs, body)
  end
  defmacro field(identifier, type, do: body) when is_atom(type) do
    field_definition(identifier, [type: type], body)
  end

  @spec field_definition(atom, Keyword.t, Macro.t) :: Macro.t
  def field_definition(identifier, attrs, body) do
    {desc, attrs} =
      attrs
      |> Keyword.put_new(:name, default_field_name(identifier))
      |> Keyword.pop(:description)

    [
      quote do
        @absinthe_blueprint unquote(__MODULE__).put_field(
          @absinthe_blueprint,
          hd(@absinthe_scopes),
          %Absinthe.Blueprint.Schema.FieldDefinition{
            unquote_splicing(attrs),
            description: @desc || unquote(desc),
            identifier: unquote(identifier),
          }
        )
        @absinthe_scopes [{:field, hd(@absinthe_scopes), unquote(identifier)} | @absinthe_scopes]
        @desc nil
      end,
      body,
      pop_scope()
    ]
  end

  defp default_field_name(identifier) do
    identifier
    |> Atom.to_string
    |> Absinthe.Utils.camelize(lower: true)
  end

  defmacro resolve(fun) do
    quote do
      @absinthe_blueprint unquote(__MODULE__).put_attrs(
        @absinthe_blueprint,
        hd(@absinthe_scopes),
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
