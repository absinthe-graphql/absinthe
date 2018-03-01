# TODO: This will become Absinthe.Schema.Notatigon before release
defmodule Absinthe.Schema.Notation.Experimental do

  alias Absinthe.Blueprint
  alias Absinthe.Blueprint.Schema

  defmacro __using__(_opts) do
    Module.register_attribute(__CALLER__.module, :absinthe_blueprint, [])
    Module.put_attribute(__CALLER__.module, :absinthe_blueprint, [%Absinthe.Blueprint{}])
    Module.register_attribute(__CALLER__.module, :absinthe_desc, [accumulate: true])
    quote do
      Module.register_attribute(__MODULE__, :__absinthe_type_import__, accumulate: true)
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

  defmacro import_types(type_module_ast, opts \\ []) do
    env = __CALLER__

    type_module_ast
    |> Macro.expand(env)
    |> do_import_types(env, opts)
  end

  defp do_import_types({{:., _, [root_ast, :{}]}, _, modules_ast_list}, env, opts) do
    {:__aliases__, _, root} = root_ast

    root_module = Module.concat(root)
    root_module_with_alias = Keyword.get(env.aliases, root_module, root_module)

    for {_, _, leaf} <- modules_ast_list do
      type_module = Module.concat([root_module_with_alias | leaf])
      if Code.ensure_loaded?(type_module) do
        do_import_types(type_module, env, opts)
      else
        raise ArgumentError, "module #{type_module} is not available"
      end
    end
  end

  defp do_import_types(module, env, opts) do
    Module.put_attribute(env.module, :__absinthe_type_imports__, [{module, opts} | Module.get_attribute(env.module, :__absinthe_type_imports__) || []])
    []
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

    field = struct(Schema.FieldDefinition, attrs)

    put_attr(caller.module, field)

    [
      quote do
        unquote(__MODULE__).put_desc(__MODULE__, Schema.FieldDefinition, unquote(identifier))
      end,
      body,
      quote do: unquote(__MODULE__).close_scope()
    ]
  end

  def put_desc(module, type, identifier) do
    Module.put_attribute(module, :absinthe_desc, {{type, identifier}, Module.get_attribute(module, :desc)})
    Module.put_attribute(module, :desc, nil)
  end

  def object_definition(caller, identifier, attrs, body) do
    attrs =
      attrs
      |> Keyword.put(:identifier, identifier)
      |> Keyword.put_new(:name, default_object_name(identifier))

    object = struct(Schema.ObjectTypeDefinition, attrs)

    put_attr(caller.module, object)

    [
      quote do
        unquote(__MODULE__).put_desc(__MODULE__, Schema.ObjectTypeDefinition, unquote(identifier))
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
    put_attr(__CALLER__.module, {:middleware, module, opts})
    []
  end

  def noop(_desc) do
    :ok
  end

  defmacro __before_compile__(env) do
    module_attribute_descs =
      env.module
      |> Module.get_attribute(:absinthe_desc)
      |> Map.new

    attrs =
      env.module
      |> Module.get_attribute(:absinthe_blueprint)
      |> Enum.reverse
      |> intersperse_descriptions(module_attribute_descs)

    imports = Module.get_attribute(env.module, :__absinthe_type_imports__) || []

    blueprint =
      attrs
      |> build_blueprint()
      |> add_imports(imports)

    quote do
      unquote(__MODULE__).noop(@desc)
      def __absinthe_blueprint__ do
        unquote(Macro.escape(blueprint))
      end
    end
  end

  defp add_imports(blueprint, imports) do
    Enum.reduce(imports, blueprint, fn
      {module, []}, blueprint ->
        %{schema_definitions: types} = module.__absinthe_blueprint__()
        Map.update!(blueprint, :schema_definitions, &(types ++ &1))

      {module, [only: only]}, blueprint ->
        %{schema_definitions: types} = module.__absinthe_blueprint__()
        types = Enum.filter(types, fn type -> type.identifier in only end)
        Map.update!(blueprint, :schema_definitions, &(types ++ &1))

      {module, [except: except]}, blueprint ->
        %{schema_definitions: types} = module.__absinthe_blueprint__()
        types = Enum.filter(types, fn type -> not(type.identifier in except) end)
        Map.update!(blueprint, :schema_definitions, &(types ++ &1))
    end)
  end

  defp intersperse_descriptions(attrs, descs) do
    Enum.flat_map(attrs, fn
      %struct{identifier: identifier} = val ->
        case Map.get(descs, {struct, identifier}) do
          nil -> [val]
          desc -> [val, {:desc, desc}]
        end
      val ->
        [val]
    end)
  end

  defp build_blueprint([%Absinthe.Blueprint{} = bp | attrs]) do
    build_types(attrs, [bp])
  end
  defp build_types([], [bp]) do
    Map.update!(bp, :schema_definitions, &Enum.reverse/1)
  end
  defp build_types([%Schema.ObjectTypeDefinition{} = obj | rest], stack) do
    build_types(rest, [obj | stack])
  end
  defp build_types([%Schema.FieldDefinition{} = field | rest], stack) do
    build_types(rest, [field | stack])
  end
  defp build_types([{:desc, desc} | rest], [item | stack]) do
    build_types(rest, [%{item | description: desc} | stack])
  end
  defp build_types([{:middleware, module, opts} | rest], [field | stack]) do
    field = Map.update!(field, :middleware_ast, &[{module, opts} | &1])
    build_types(rest, [field | stack])
  end
  defp build_types([:close | rest], [%Schema.FieldDefinition{} = field, obj | stack]) do
    field = Map.update!(field, :middleware_ast, &Enum.reverse/1)
    obj = Map.update!(obj, :fields, &[field | &1])
    build_types(rest, [obj | stack])
  end
  defp build_types([:close | rest], [%Schema.ObjectTypeDefinition{} = obj, bp]) do
    obj = Map.update!(obj, :fields, &Enum.reverse/1)
    bp = Map.update!(bp, :schema_definitions, &[obj | &1])
    build_types(rest, [bp])
  end

end
