# TODO: This will become Absinthe.Schema.Notatigon before release
defmodule Absinthe.Schema.Notation.Experimental do

  alias Absinthe.Blueprint

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
    # Enum.reduce(selected, blueprint, &put_field(&2, scope, &1))
  end
  defp do_concat_fields(_, _, _, criteria, _) do
    raise "Not a valid source for fields: #{inspect(criteria)}"
  end

  defmacro __using__(_opts) do
    Module.register_attribute(__CALLER__.module, :absinthe_blueprint, [])
    Module.put_attribute(__CALLER__.module, :absinthe_blueprint, [%Absinthe.Blueprint{}])
    Module.register_attribute(__CALLER__.module, :absinthe_desc, [accumulate: true])
    quote do
      @desc nil
      import unquote(__MODULE__), only: :macros
      @before_compile unquote(__MODULE__)
    end
  end

  defmacro query(do: body) do
    object_definition(__CALLER__, :query, [name: "RootQueryType"], body)
  end
  defmacro query(attrs, do: body) when is_list(attrs) do
    object_definition(__CALLER__, :query, attrs, body)
  end

  defmacro mutation(do: body) do
    object_definition(__CALLER__, :mutation, [name: "RootMutationType"], body)
  end
  defmacro mutation(attrs, do: body) when is_list(attrs) do
    object_definition(__CALLER__, :mutation, attrs, body)
  end

  defmacro subscription(do: body) do
    object_definition(__CALLER__, :subscription, [name: "RootSubscriptionType"], body)
  end
  defmacro subscription(attrs, do: body) when is_list(attrs) do
    object_definition(__CALLER__, :subscription, attrs, body)
  end

  defmacro object(identifier, do: body) do
    object_definition(__CALLER__, identifier, [], body)
  end

  defmacro object(identifier, attrs, do: body) do
    object_definition(__CALLER__, identifier, attrs, body)
  end

  defp put_attr(module, thing) do
    existing = Module.get_attribute(module, :absinthe_blueprint)
    Module.put_attribute(module, :absinthe_blueprint, [thing | existing])
  end

  defmacro close_scope() do
    put_attr(__CALLER__.module, :close)
    []
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
    end
  end

  @spec field(atom, atom | Keyword.t) :: Macro.t
  defmacro field(identifier, attrs) when is_list(attrs) do
    field_definition(__CALLER__, identifier, attrs, nil)
  end
  defmacro field(identifier, type) when is_atom(type) do
    field_definition(__CALLER__, identifier, [type: type], nil)
  end

  @spec field(atom, atom | Keyword.t, [do: Macro.t]) :: Macro.t
  defmacro field(identifier, attrs, do: body) when is_list(attrs) do
    field_definition(__CALLER__, identifier, attrs, body)
  end
  defmacro field(identifier, type, do: body) when is_atom(type) do
    field_definition(__CALLER__, identifier, [type: type], body)
  end

  def field_definition(caller, identifier, attrs, body) do
    attrs =
      attrs
      |> Keyword.put(:identifier, identifier)
      |> Keyword.put_new(:name, default_field_name(identifier))

    field = struct(Absinthe.Blueprint.Schema.FieldDefinition, attrs)

    put_attr(caller.module, field)

    [
      quote do
        Module.put_attribute(__MODULE__, :absinthe_desc, {unquote(identifier), @desc})
        @desc nil
      end,
      [],
      quote do: unquote(__MODULE__).close_scope()
    ]
  end

  def object_definition(caller, identifier, attrs, body) do
    attrs =
      attrs
      |> Keyword.put(:identifier, identifier)
      |> Keyword.put_new(:name, default_object_name(identifier))

    object = struct(Absinthe.Blueprint.Schema.ObjectTypeDefinition, attrs)

    put_attr(caller.module, object)

    [
      quote do
        @absinthe_desc {:desc, @desc}
        @desc nil
      end,
      body,
      quote do: unquote(__MODULE__).close_scope()
    ]
  end

  defp default_field_name(identifier) do
    identifier
    |> Atom.to_string
    |> Absinthe.Utils.camelize(lower: true)
  end

  defmacro resolve(fun) do
    quote do
      middleware Absinthe.Resolution, unquote(fun)
    end
  end

  defmacro middleware(module, opts) do
    quote do
      # @absinthe_blueprint unquote(__MODULE__).put_attrs(
      #   @absinthe_blueprint,
      #   hd(@absinthe_scopes),
      #   middleware: [{unquote(module), unquote(Macro.escape(opts))}]
      # )
    end
  end

  defmacro __before_compile__(env) do
    attrs =
      env.module
      |> Module.get_attribute(:absinthe_blueprint)
      |> Enum.reverse
    blueprint = build_blueprint(attrs)
    quote do
      def __absinthe_blueprint__ do
        unquote(Macro.escape(blueprint))
      end
    end
  end

  alias Absinthe.Blueprint.Schema
  defp build_blueprint([%Absinthe.Blueprint{} = bp | attrs]) do
    types = build_types(attrs, [], %{types: []})
    Map.merge(bp, types)
  end

  defp build_types([%Schema.ObjectTypeDefinition{} = obj | rest], tmp, finished) do
    finished
  end

end
