# TODO: This will become Absinthe.Schema.Notatigon before release
defmodule Absinthe.Schema.Notation do
  alias Absinthe.Blueprint
  alias Absinthe.Blueprint.Schema

  defmacro __using__(_opts) do
    Module.register_attribute(__CALLER__.module, :absinthe_blueprint, [])
    Module.put_attribute(__CALLER__.module, :absinthe_blueprint, [%Absinthe.Blueprint{}])
    Module.register_attribute(__CALLER__.module, :absinthe_desc, accumulate: true)

    quote do
      Module.register_attribute(__MODULE__, :__absinthe_type_import__, accumulate: true)
      @desc nil
      import unquote(__MODULE__), only: :macros
      @before_compile unquote(__MODULE__)
    end
  end

  defmacro query(attrs \\ [], do: body) when is_list(attrs) do
    scoped_def(__CALLER__, Schema.ObjectTypeDefinition, :query, attrs, body)
  end

  defmacro mutation(attrs \\ [], do: body) when is_list(attrs) do
    scoped_def(__CALLER__, Schema.ObjectTypeDefinition, :mutation, attrs, body)
  end

  defmacro subscription(attrs \\ [], do: body) when is_list(attrs) do
    scoped_def(__CALLER__, Schema.ObjectTypeDefinition, :subscription, attrs, body)
  end

  defmacro object(identifier, attrs \\ [], do: body) do
    scoped_def(__CALLER__, Schema.ObjectTypeDefinition, identifier, attrs, body)
  end

  @spec field(atom, atom | Keyword.t()) :: Macro.t()
  defmacro field(identifier, attrs) when is_list(attrs) do
    scoped_def(__CALLER__, Schema.FieldDefinition, identifier, attrs, nil)
  end

  defmacro field(identifier, type) do
    scoped_def(__CALLER__, Schema.FieldDefinition, identifier, [type: type], nil)
  end

  @spec field(atom, atom | Keyword.t(), do: Macro.t()) :: Macro.t()
  defmacro field(identifier, attrs, do: body) when is_list(attrs) do
    scoped_def(__CALLER__, Schema.FieldDefinition, identifier, attrs, body)
  end

  defmacro field(identifier, type, do: body) do
    scoped_def(__CALLER__, Schema.FieldDefinition, identifier, [type: type], body)
  end

  defmacro resolve(fun) do
    quote do
      middleware Absinthe.Resolution, unquote(fun)
    end
  end

  defmacro middleware(module, opts) do
    put_attr(__CALLER__.module, {:middleware, module, opts})
  end

  defmacro description(str) do
    put_attr(__CALLER__.module, {:desc, str})
  end

  defmacro scalar(identifier, attrs \\ [], do: body) do
    scoped_def(__CALLER__, Schema.ScalarTypeDefinition, identifier, attrs, body)
  end

  defmacro serialize(fun_ast) do
    put_attr(__CALLER__.module, {:serialize, fun_ast})
  end

  defmacro parse(fun_ast) do
    put_attr(__CALLER__.module, {:parse, fun_ast})
  end

  defmacro enum(identifier, do: body) do
    scoped_def(__CALLER__, Schema.EnumTypeDefinition, identifier, [], body)
  end

  defmacro enum(identifier, attrs) do
    scoped_def(__CALLER__, Schema.EnumTypeDefinition, identifier, attrs, nil)
  end

  defmacro enum(identifier, attrs, do: body) do
    scoped_def(__CALLER__, Schema.EnumTypeDefinition, identifier, attrs, body)
  end

  defmacro arg(identifier, type, attrs) do
    record_arg(__CALLER__, identifier, Keyword.put(attrs, :type, type))
  end

  defmacro arg(identifier, attrs) when is_list(attrs) do
    record_arg(__CALLER__, identifier, attrs)
  end

  defmacro arg(identifier, type) do
    record_arg(__CALLER__, identifier, type: type)
  end

  defp record_arg(caller, identifier, attrs) do
    attrs =
      attrs
      |> Keyword.put(:identifier, identifier)
      |> Keyword.put_new(:name, default_name(:arg, identifier))

    put_attr(caller.module, {:arg, attrs})
  end

  defmacro non_null(type) do
    quote do
      %Absinthe.Type.NonNull{of_type: unquote(type)}
    end
  end

  defmacro directive(identifier, attrs \\ [], do: body) do
  end

  @spec import_fields(atom | {module, atom}, Keyword.t()) :: Macro.t()
  defmacro import_fields(source_criteria, opts \\ []) do
    source_criteria =
      source_criteria
      |> Macro.prewalk(&Macro.expand(&1, __CALLER__))

    put_attr(__CALLER__.module, {:import_fields, {source_criteria, opts}})
  end

  defmacro import_types(type_module_ast, opts \\ []) do
    env = __CALLER__

    type_module_ast
    |> Macro.expand(env)
    |> do_import_types(env, opts)
  end

  defmacro close_scope() do
    put_attr(__CALLER__.module, :close)
  end

  defp scoped_def(caller, type, identifier, attrs, body) do
    attrs =
      attrs
      |> Keyword.put(:identifier, identifier)
      |> Keyword.put_new(:name, default_name(type, identifier))

    scalar = struct(type, attrs)

    put_attr(caller.module, scalar)

    [
      quote do
        unquote(__MODULE__).put_desc(__MODULE__, unquote(type), unquote(identifier))
      end,
      body,
      quote(do: unquote(__MODULE__).close_scope())
    ]
  end

  defp put_attr(module, thing) do
    existing = Module.get_attribute(module, :absinthe_blueprint)
    Module.put_attribute(module, :absinthe_blueprint, [thing | existing])
    []
  end

  defp default_name(Schema.FieldDefinition, identifier) do
    identifier
    |> Atom.to_string()
  end

  defp default_name(_, identifier) do
    identifier
    |> Atom.to_string()
    |> Absinthe.Utils.camelize()
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
    Module.put_attribute(env.module, :__absinthe_type_imports__, [
      {module, opts} | Module.get_attribute(env.module, :__absinthe_type_imports__) || []
    ])

    []
  end

  def put_desc(module, type, identifier) do
    Module.put_attribute(
      module,
      :absinthe_desc,
      {{type, identifier}, Module.get_attribute(module, :desc)}
    )

    Module.put_attribute(module, :desc, nil)
  end

  def noop(_desc) do
    :ok
  end

  defmacro __before_compile__(env) do
    module_attribute_descs =
      env.module
      |> Module.get_attribute(:absinthe_desc)
      |> Map.new()

    attrs =
      env.module
      |> Module.get_attribute(:absinthe_blueprint)
      |> List.insert_at(0, :close)
      |> Enum.reverse()
      |> intersperse_descriptions(module_attribute_descs)

    imports = Enum.uniq(Module.get_attribute(env.module, :__absinthe_type_imports__) || [])

    schema_def = %Schema.SchemaDefinition{
      imports: imports,
      module: env.module
    }

    blueprint =
      attrs
      |> List.insert_at(1, schema_def)
      |> build_blueprint()

    # TODO: handle multiple schemas
    [schema] = blueprint.schema_definitions

    middleware =
      for %Schema.ObjectTypeDefinition{} = type <- schema.types,
          field <- type.fields do
        quote do
          def __absinthe_middleware__(unquote(type.identifier), unquote(field.identifier)) do
            unquote(field.middleware_ast)
          end
        end
      end

    quote do
      unquote(__MODULE__).noop(@desc)

      def __absinthe_blueprint__ do
        unquote(Macro.escape(blueprint))
      end

      unquote_splicing(middleware)
    end
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

  defp build_types([%Schema.SchemaDefinition{} = schema | rest], stack) do
    build_types(rest, [schema | stack])
  end

  @simple_open [
    Schema.ScalarTypeDefinition,
    Schema.ObjectTypeDefinition,
    Schema.FieldDefinition,
    Schema.EnumTypeDefinition
  ]

  defp build_types([%module{} = type | rest], stack) when module in @simple_open do
    build_types(rest, [type | stack])
  end

  defp build_types([{:import_fields, criterion} | rest], [obj | stack]) do
    obj = Map.update!(obj, :imports, &[criterion | &1])
    build_types(rest, [obj | stack])
  end

  defp build_types([{:desc, desc} | rest], [item | stack]) do
    build_types(rest, [%{item | description: desc} | stack])
  end

  defp build_types([{:middleware, module, opts} | rest], [field | stack]) do
    field = Map.update!(field, :middleware_ast, &[{module, opts} | &1])
    build_types(rest, [field | stack])
  end

  defp build_types([{:arg, attrs} | rest], [field | stack]) do
    field = Map.update!(field, :arguments, &[attrs | &1])
    build_types(rest, [field | stack])
  end

  defp build_types([{attr, value} | rest], [entity | stack]) do
    entity = %{entity | attr => value}
    build_types(rest, [entity | stack])
  end

  defp build_types([:close | rest], [%Schema.FieldDefinition{} = field, obj | stack]) do
    field = Map.update!(field, :middleware_ast, &Enum.reverse/1)
    obj = Map.update!(obj, :fields, &[field | &1])
    build_types(rest, [obj | stack])
  end

  defp build_types([:close | rest], [%Schema.ObjectTypeDefinition{} = obj, schema | stack]) do
    obj = Map.update!(obj, :fields, &Enum.reverse/1)
    schema = Map.update!(schema, :types, &[obj | &1])
    build_types(rest, [schema | stack])
  end

  @simple_close [
    Schema.ScalarTypeDefinition,
    Schema.EnumTypeDefinition
  ]

  defp build_types([:close | rest], [%module{} = type, schema | stack])
       when module in @simple_close do
    schema = Map.update!(schema, :types, &[type | &1])
    build_types(rest, [schema | stack])
  end

  defp build_types([:close | rest], [%Schema.SchemaDefinition{} = schema, bp]) do
    bp = Map.update!(bp, :schema_definitions, &[schema | &1])
    build_types(rest, [bp])
  end
end
