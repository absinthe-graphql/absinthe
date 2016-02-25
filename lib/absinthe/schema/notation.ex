defmodule Absinthe.Schema.Notation do
  alias Absinthe.Utils
  alias Absinthe.Type
  alias Absinthe.Schema.Notation.Scope

  defmacro __using__(_opts) do
    quote do
      import unquote(__MODULE__), only: :macros
      Module.register_attribute __MODULE__, :absinthe_errors, accumulate: true
      Module.register_attribute __MODULE__, :absinthe_types, accumulate: true
      Module.register_attribute __MODULE__, :absinthe_directives, accumulate: true
      Module.register_attribute __MODULE__, :absinthe_exports, accumulate: true
      Module.register_attribute __MODULE__, :absinthe_interface_implementors, accumulate: true
      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(_env) do
    quote do

      def __absinthe_type__(_), do: nil

      @absinthe_type_map Enum.into(@absinthe_types, %{})
      def __absinthe_types__, do: @absinthe_type_map

      def __absinthe_directive__(_), do: nil

      @absinthe_directive_map Enum.into(@absinthe_directives, %{})
      def __absinthe_directives__, do: @absinthe_directive_map

      def __absinthe_errors__, do: @absinthe_errors

      @absinthe_interface_implementors_map Enum.reduce(@absinthe_interface_implementors, %{}, fn
        {iface, obj_ident}, acc ->
          update_in(acc, [iface], fn
            nil ->
              [obj_ident]
            impls ->
              [obj_ident | impls]
          end)
      end)
      def __absinthe_interface_implementors__ do
        @absinthe_interface_implementors_map
      end
      def __absinthe_exports__, do: @absinthe_exports

    end
  end

  Module.register_attribute(__MODULE__, :placement, accumulate: true)

  def __attrs__(attrs_ast) do
    attrs_ast
    |> Macro.escape
  end

  def __scope__(env, kind, identifier, attrs, block) do
    [
      __open_scope__(kind, env.module, identifier, attrs),
      block,
      __close_scope__(kind, env.module, identifier)
    ]
  end

  def add_reference(attrs, env, identifier) do
    attrs
    |> Keyword.put(
      :__reference__,
      quote bind_quoted: [module: env.module, line: env.line, file: env.file, identifier: identifier], do: %{
        module: module,
        identifier: identifier,
        location: %{
          file: file,
          line: line
        }
      }
    )
  end

  def add_description_from_module_attribute(attrs_ast, mod) do
    case {attrs_ast[:description], Module.get_attribute(mod, :desc)} do
      {_, nil} ->
        attrs_ast
      {nil, doc} ->
        Module.put_attribute(mod, :desc, nil)
        Keyword.put(attrs_ast, :description, String.strip(doc))
      {_, _} ->
        attrs_ast
    end
  end

  # OPEN SCOPE HOOKS

  def __open_scope__(kind, mod, identifier, raw_attrs) do
    attrs = __attrs__(raw_attrs)
    quote bind_quoted: [kind: kind, identifier: identifier, mod: mod, attrs: attrs, notation: __MODULE__] do
      notation.check_placement!(mod, kind)
      Scope.open(
        kind,
        mod,
        attrs
        |> notation.add_description_from_module_attribute(mod)
        |> notation.add_reference(__ENV__, identifier)
      )
    end
  end

  # CLOSE SCOPE HOOKS

  def __close_scope__(:enum, mod, identifier) do
    __close_scope_and_define_type__(Type.Enum, mod, identifier)
  end

  @unexported_identifiers ~w(query mutation subscription)a
  def __close_scope__(:object, mod, identifier) do
    __close_scope_and_define_type__(
      Type.Object, mod, identifier,
      export: !Enum.member?(@unexported_identifiers, identifier)
    )
  end

  def __close_scope__(:interface, mod, identifier) do
    __close_scope_and_define_type__(Type.Interface, mod, identifier)
  end

  def __close_scope__(:union, mod, identifier) do
    __close_scope_and_define_type__(Type.Union, mod, identifier)
  end

  def __close_scope__(:input_object, mod, identifier) do
    __close_scope_and_define_type__(Type.InputObject, mod, identifier)
  end

  def __close_scope__(:field, mod, identifier) do
    __close_scope_and_accumulate_attribute__(:fields, mod, identifier)
  end

  def __close_scope__(:arg, mod, identifier) do
    __close_scope_and_accumulate_attribute__(:args, mod, identifier)
  end

  def __close_scope__(:scalar, mod, identifier) do
    __close_scope_and_define_type__(Type.Scalar, mod, identifier)
  end

  def __close_scope__(:directive, mod, identifier) do
    __close_scope_and_define_directive__(mod, identifier)
  end

  def __close_scope__(_, mod, _) do
    quote do
      Scope.close(unquote(mod))
    end
  end

  defp __close_scope_and_define_directive__(mod, identifier, def_opts \\ []) do
    scope_module = __MODULE__.Scope
    quote bind_quoted: [mod: mod, identifier: identifier, module: __MODULE__, scope_module: scope_module, def_opts: def_opts] do
      attrs = scope_module.close(mod).attrs |> module.__with_name__(identifier)
      type_obj = Absinthe.Type.Directive.build(identifier, attrs)
      Module.eval_quoted(__ENV__, [
        module.__define_directive__({identifier, attrs[:name]}, type_obj, def_opts)
      ])
    end
  end

  defp __close_scope_and_define_type__(type_module, mod, identifier, def_opts \\ []) do
    scope_module = __MODULE__.Scope
    quote bind_quoted: [type_module: type_module, mod: mod, identifier: identifier, module: __MODULE__, scope_module: scope_module, def_opts: def_opts] do
      attrs = scope_module.close(mod).attrs |> module.__with_name__(identifier, title: true)
      type_obj = type_module.build(identifier, attrs)
      Module.eval_quoted(__ENV__, [
          module.__define_type__({identifier, attrs[:name]}, type_obj, def_opts),
          (if attrs[:interfaces], do: module.__register_interface_implementor__(identifier, attrs[:interfaces]))
      ])
    end
  end

  defp __close_scope_and_accumulate_attribute__(attr_name, mod, identifier) do
    scope_module = __MODULE__.Scope
    quote bind_quoted: [attr_name: attr_name, mod: mod, identifier: identifier, module: __MODULE__, scope_module: scope_module] do
      attrs = scope_module.close(mod).attrs |> module.__with_name__(identifier)
      scope_module.put_attribute(mod, attr_name, {identifier, attrs}, accumulate: true)
    end
  end

  def put_attribute(macro_name, key, value, opts \\ [accumulate: false]) do
    quote bind_quoted: [macro_name: macro_name, notation: __MODULE__, key: key, value: value, opts: opts] do
      notation.check_placement!(__MODULE__, macro_name)
      Scope.put_attribute(__MODULE__, key, value, opts)
    end
  end

  # OBJECT

  @placement {:object, [toplevel: true]}
  defmacro object(identifier, attrs, [do: block]) do
    __scope__(__CALLER__, :object, identifier, attrs, block)
  end
  defmacro object(identifier, [do: block]) do
    __scope__(__CALLER__, :object, identifier, [], block)
  end

  @doc """
  Declare implemented interfaces for an object.
  """
  @placement {:interfaces, [under: :object]}
  defmacro interfaces(ifaces) when is_list(ifaces) do
    quote bind_quoted: [notation: __MODULE__, ifaces: ifaces] do
      notation.check_placement!(__MODULE__, :interfaces)
      Scope.put_attribute(__MODULE__, :interfaces, ifaces)
    end
  end

  # TODO: Support different interface checks

  @doc """
  Declare an implemented interface for an object.
  """
  @placement {:interface_attribute, [under: :object]}
  defmacro interface(identifier) do
    quote bind_quoted: [notation: __MODULE__, identifier: identifier] do
      notation.check_placement!(__MODULE__, :interface_attribute, as: "`interface` (as an attribute)")
      Scope.put_attribute(
        __MODULE__,
        :interfaces,
        identifier,
        accumulate: true
      )
    end
  end

  # INTERFACES

  @placement {:interface, [toplevel: :true]}
  defmacro interface(identifier, attrs, [do: block]) do
    __scope__(__CALLER__, :interface, identifier, attrs, block)
  end
  defmacro interface(identifier, [do: block]) do
    __scope__(__CALLER__, :interface, identifier, [], block)
  end


  @placement {:resolve_type, [under: [:interface, :union]]}
  defmacro resolve_type(func_ast) do
    quote bind_quoted: [notation: __MODULE__, func: Macro.escape(func_ast)] do
      notation.check_placement!(__MODULE__, :resolve_type)
      Scope.put_attribute(__MODULE__, :resolve_type, func)
    end
  end

  # FIELDS

  @placement {:field, [under: [:input_object, :interface, :object]]}
  defmacro field(identifier, [do: block]) do
    __scope__(__CALLER__, :field, identifier, [], block)
  end
  defmacro field(identifier, attrs) when is_list(attrs) do
    __scope__(__CALLER__, :field, identifier, attrs, nil)
  end
  defmacro field(identifier, type) do
    __scope__(__CALLER__, :field, identifier, [type: type], nil)
  end

  defmacro field(identifier, attrs, [do: block]) when is_list(attrs) do
    __scope__(__CALLER__, :field, identifier, attrs, block)
  end
  defmacro field(identifier, type, [do: block]) do
    __scope__(__CALLER__, :field, identifier, [type: type], block)
  end
  defmacro field(identifier, type, attrs) do
    __scope__(__CALLER__, :field, identifier, Keyword.put(attrs, :type, type),  nil)
  end
  defmacro field(identifier, type, attrs, [do: block]) do
    __scope__(__CALLER__, :field, identifier, Keyword.put(attrs, :type, type), block)
  end

  @placement {:resolve, [under: [:field]]}
  defmacro resolve(func_ast) do
    quote bind_quoted: [notation: __MODULE__, func: Macro.escape(func_ast)] do
      notation.check_placement!(__MODULE__, :resolve)
      Scope.put_attribute(__MODULE__, :resolve, func)
    end
  end

  @placement {:is_type_of, [under: [:object]]}
  defmacro is_type_of(func_ast) do
    quote bind_quoted: [notation: __MODULE__, func: Macro.escape(func_ast)] do
      notation.check_placement!(__MODULE__, :is_type_of)
      Scope.put_attribute(__MODULE__, :is_type_of, func)
    end
  end

  # ARGS

  @placement {:arg, [under: [:directive, :field]]}
  defmacro arg(identifier, type, attrs) do
    __scope__(__CALLER__, :arg, identifier, Keyword.put(attrs, :type, type), nil)
  end
  defmacro arg(identifier, attrs) when is_list(attrs) do
    __scope__(__CALLER__, :arg, identifier, attrs, nil)
  end
  defmacro arg(identifier, type) do
    __scope__(__CALLER__, :arg, identifier, [type: type], nil)
  end

  # SCALARS

  @placement {:scalar, [toplevel: true]}
  defmacro scalar(identifier, attrs, [do: block]) do
    __scope__(__CALLER__, :scalar, identifier, attrs, block)
  end
  defmacro scalar(identifier, [do: block]) do
    __scope__(__CALLER__, :scalar, identifier, [], block)
  end
  defmacro scalar(identifier, attrs) do
    __scope__(__CALLER__, :scalar, identifier, attrs, nil)
  end

  @placement {:serialize, [under: [:scalar]]}
  defmacro serialize(func_ast) do
    quote bind_quoted: [notation: __MODULE__, func: Macro.escape(func_ast)] do
      notation.check_placement!(__MODULE__, :serialize)
      Scope.put_attribute(__MODULE__, :serialize, func)
    end
  end

  @placement {:parse, [under: [:scalar]]}
  defmacro parse(func_ast) do
    quote bind_quoted: [notation: __MODULE__, func: Macro.escape(func_ast)] do
      notation.check_placement!(__MODULE__, :parse)
      Scope.put_attribute(__MODULE__, :parse, func)
    end
  end

  # DIRECTIVES

  @placement {:directive, [toplevel: true]}
  defmacro directive(identifier, attrs, [do: block]) do
    __scope__(__CALLER__, :directive, identifier, attrs, block)
  end
  defmacro directive(identifier, [do: block]) do
    __scope__(__CALLER__, :directive, identifier, [], block)
  end

  @doc """
  Declare a directive as operating an a AST node type
  """
  @placement {:on, [under: :directive]}
  defmacro on(ast_node) do
    quote bind_quoted: [ast_node: ast_node, notation: __MODULE__] do
      notation.check_placement!(__MODULE__, :on)
      ast_node
      |> List.wrap
      |> Enum.each(fn
        value ->
          Scope.put_attribute(
            __MODULE__,
            :on,
            value,
            accumulate: true
          )
      end)
    end
  end

  @doc """
  Calculate the instruction for a directive
  """
  @placement {:instruction, [under: :directive]}
  defmacro instruction(func_ast) do
    quote bind_quoted: [notation: __MODULE__, func: Macro.escape(func_ast)] do
      notation.check_placement!(__MODULE__, :instruction)
      Scope.put_attribute(__MODULE__, :instruction, func)
    end
  end

  # INPUT OBJECTS

  @placement {:input_object, [toplevel: true]}
  defmacro input_object(identifier, attrs, [do: block]) do
    __scope__(__CALLER__, :input_object, identifier, attrs, block)
  end
  defmacro input_object(identifier, [do: block]) do
    __scope__(__CALLER__, :input_object, identifier, [], block)
  end

  # UNIONS

  @placement {:union, [toplevel: true]}
  defmacro union(identifier, attrs, [do: block]) do
    __scope__(__CALLER__, :union, identifier, attrs, block)
  end
  defmacro union(identifier, [do: block]) do
    __scope__(__CALLER__, :union, identifier, [], block)
  end

  @placement {:types, [under: [:union]]}
  defmacro types(types) do
    quote bind_quoted: [notation: __MODULE__, types: types] do
      notation.check_placement!(__MODULE__, :types)
      Scope.put_attribute(__MODULE__, :types, List.wrap(types))
    end
  end

  # ENUMS

  @placement {:enum, [toplevel: true]}
  defmacro enum(identifier, attrs, [do: block]) do
    __scope__(__CALLER__, :enum, identifier, attrs, block)
  end
  defmacro enum(identifier, [do: block]) do
    __scope__(__CALLER__, :enum, identifier, [], block)
  end
  defmacro enum(identifier, attrs) do
    __scope__(__CALLER__, :enum, identifier, attrs, nil)
  end

  @placement {:value, [under: [:enum]]}
  defmacro value(identifier, raw_attrs \\ []) do
    attrs = raw_attrs
    |> Keyword.put(:value, Keyword.get(raw_attrs, :as, identifier))
    |> Keyword.delete(:as)
    quote bind_quoted: [identifier: identifier, notation: __MODULE__, attrs: attrs] do
      notation.check_placement!(__MODULE__, :value)
      Scope.put_attribute(__MODULE__, :values, {identifier, attrs |> notation.add_description_from_module_attribute(__MODULE__)}, accumulate: true)
    end
  end

  # UTILITIES

  @placement {:import_types, [toplevel: true]}
  defmacro import_types(type_module_ast, opts_ast \\ []) do
    opts = Macro.expand(opts_ast, __CALLER__)
    type_module = Macro.expand(type_module_ast, __CALLER__)
    types = for {ident, _} = naming <- type_module.__absinthe_types__, into: [] do
      if Enum.member?(type_module.__absinthe_exports__, ident) do
        ast = quote do
          unquote(type_module).__absinthe_type__(unquote(ident))
        end
        __define_type__(naming, ast, opts)
      end
    end
    directives = for {ident, name} <- type_module.__absinthe_directives__, into: [] do
      if Enum.member?(type_module.__absinthe_exports__, ident) do
        ast = quote do
          unquote(type_module).__absinthe_directive__(unquote(ident))
        end
        __define_directive__({ident, name}, ast, opts)
      end
    end
    types ++ directives
  end

  @spec __with_name__(Keyword.t, Type.identifier_t) :: Keyword.t
  @spec __with_name__(Keyword.t, Type.identifier_t, Keyword.t) :: Keyword.t
  def __with_name__(attrs, identifier, opts \\ []) do
    update_in(attrs, [:name], fn
      value ->
        default_name(identifier, value, opts)
    end)
  end

  defp default_name(identifier, nil, opts) do
    if opts[:title] do
      identifier |> Atom.to_string |> Utils.camelize
    else
      identifier |> Atom.to_string
    end
  end
  defp default_name(_, name, _) do
    name
  end

  def __register_interface_implementor__(identifier, interfaces) do
    interfaces
    |> Enum.map(fn
      iface ->
        quote do
          @absinthe_interface_implementors {unquote(iface), unquote(identifier)}
        end
    end)
  end

  def __define_type__({identifier, name}, ast, opts \\ []) do
    quote do
      type_status = {
        Keyword.has_key?(@absinthe_types, unquote(identifier)),
        Enum.member?(Keyword.values(@absinthe_types), unquote(name))
      }
      if match?({true, _}, type_status) do
        @absinthe_errors %{
          rule: Absinthe.Schema.Rule.TypeNamesAreUnique,
          location: %{file: __ENV__.file, line: __ENV__.line},
          data: %{artifact: "Absinthe type identifier", value: unquote(identifier)}
        }
      end
      if match?({_, true}, type_status) do
        @absinthe_errors %{
          rule: Absinthe.Schema.Rule.TypeNamesAreUnique,
          location: %{file: __ENV__.file, line: __ENV__.line},
          data: %{artifact: "Type name", value: unquote(name)}
        }
      end
      if match?({false, false}, type_status) do
        @absinthe_types {unquote(identifier), unquote(name)}
        if Keyword.get(unquote(opts), :export, true) do
          @absinthe_exports unquote(identifier)
        end
        def __absinthe_type__(unquote(name)) do
          unquote(ast)
        end
        def __absinthe_type__(unquote(identifier)) do
          unquote(ast)
        end
      end
    end
  end

  def __define_directive__({identifier, name}, ast, opts \\ []) do
    quote do
      directive_status = {
        Keyword.has_key?(@absinthe_directives, unquote(identifier)),
        Enum.member?(Keyword.values(@absinthe_directives), unquote(name))
      }
      if match?({true, _}, directive_status) do
        @absinthe_errors %{
          rule: Absinthe.Schema.Rule.TypeNamesAreUnique,
          location: %{file: __ENV__.file, line: __ENV__.line},
          data: %{artifact: "Absinthe directive identifier", value: unquote(identifier)}
        }
      end
      if match?({false, false}, directive_status) do
        @absinthe_directives {unquote(identifier), unquote(name)}
        if Keyword.get(unquote(opts), :export, true) do
          @absinthe_exports unquote(identifier)
        end
        def __absinthe_directive__(unquote(name)) do
          unquote(ast)
        end
        def __absinthe_directive__(unquote(identifier)) do
          unquote(ast)
        end
      end
    end
  end

  defmacro non_null(type) do
    quote do
      %Absinthe.Type.NonNull{of_type: unquote(type)}
    end
  end

  defmacro list_of(type) do
    quote do
      %Absinthe.Type.List{of_type: unquote(type)}
    end
  end

  def check_placement!(mod, usage, opts \\ []) do
    rules = Keyword.get(@placement, usage, [])
    |> Enum.into(%{})
    do_check_placement!(mod, usage, rules, opts)
  end
  defp do_check_placement!(mod, usage, %{under: parents} = rules, opts) do
    case Scope.current(mod) do
      %{name: name} ->
        if Enum.member?(List.wrap(parents), name) do
          do_check_placement!(mod, usage, Map.delete(rules, :under), opts)
        else
          raise Absinthe.Schema.Notation.Error, only_within(usage, parents, opts)
        end
      _ ->
        raise Absinthe.Schema.Notation.Error, only_within(usage, parents, opts)
    end
  end
  defp do_check_placement!(mod, usage, %{toplevel: true} = rules, opts) do
    case Scope.current(mod) do
      nil ->
        do_check_placement!(mod, usage, Map.delete(rules, :toplevel), opts)
      _ ->
        ref = opts[:as] || "`#{usage}`"
        raise Absinthe.Schema.Notation.Error, "Invalid schema notation: #{ref} must only be used toplevel"
    end
  end
  defp do_check_placement!(_, _, rules, _) when map_size(rules) == 0 do
    :ok
  end

  defp only_within(usage, parents, opts) do
    ref = opts[:as] || "`#{usage}`"
    parts = List.wrap(parents)
    |> Enum.map(&"`#{&1}`")
    |> Enum.join(", ")
    "Invalid schema notation: #{ref} must only be used within #{parts}"
  end

end
