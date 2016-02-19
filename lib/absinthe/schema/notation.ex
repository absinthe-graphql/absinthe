defmodule Absinthe.Schema.Notation do
  alias Absinthe.Utils
  alias Absinthe.Type
  alias Absinthe.Schema.Notation.Scope

  defmacro __using__(opts) do
    quote do
      import unquote(__MODULE__)
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
          {_, result} = Map.get_and_update_(acc, iface, fn
            nil ->
              {nil, [obj_ident]}
            impls ->
              {impls, [obj_ident | impls]}
          end)
          result
      end)
      def __absinthe_interface_implementors__ do
        @absinthe_interface_implementors_map
      end
      def __absinthe_exports__, do: @absinthe_exports

    end
  end

  def __scope__(env, kind, identifier, raw_attrs, block) do
    attrs = __attrs__(env, raw_attrs)
    [
      __open_scope__(kind, env.module, identifier, attrs),
      block,
      __close_scope__(kind, env.module, identifier)
    ]
  end

  def __attrs__(caller, attrs) do
    attrs
    |> Macro.expand(caller)
    |> Macro.escape
  end

  # OPEN SCOPE HOOK

  def __open_scope__(kind, mod, identifier, attrs) do
    quote do
      Scope.open(unquote(kind), unquote(mod), unquote(attrs))
    end
  end

  # CLOSE SCOPE HOOKS

  @unexported_identifiers ~w(query mutation subscription)a
  def __close_scope__(:object, mod, identifier) do
    __close_scope_and_define_type__(
      Type.Object, mod, identifier,
      export: !Enum.member?(@unexported_identifiers, identifier)
    )
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

  def __close_scope__(_, mod, _) do
    quote do
      Scope.close(unquote(mod))
    end
  end

  defp __close_scope_and_define_type__(type_module, mod, identifier, def_opts \\ []) do
    quote bind_quoted: [type_module: type_module, mod: mod, identifier: identifier, def_opts: def_opts] do
      attrs = unquote(__MODULE__).Scope.close(mod).attrs |> unquote(__MODULE__).__with_name__(identifier)
      type_obj = type_module.build(identifier, attrs)
      definition = unquote(__MODULE__).__define_type__({identifier, attrs[:name]}, type_obj, def_opts)
      Module.eval_quoted(__ENV__, definition)
    end
  end

  defp __close_scope_and_accumulate_attribute__(attr_name, mod, identifier, name_opts \\ [lower: true]) do
    quote bind_quoted: [attr_name: attr_name, mod: mod, identifier: identifier, name_opts: name_opts] do
      attrs = Scope.close(mod).attrs |> unquote(__MODULE__).__with_name__(identifier, name_opts)
      Scope.put_attribute(mod, attr_name, {identifier, attrs}, accumulate: true)
    end
  end

  # OBJECT

  defmacro object(identifier, attrs, [do: block]) do
    __scope__(__CALLER__, :object, identifier, attrs, block)
  end
  defmacro object(identifier, [do: block]) do
    __scope__(__CALLER__, :object, identifier, [], block)
  end

  @doc """
  Declare implemented interfaces for an object.
  """
  defmacro interfaces(ifaces) when is_list(ifaces) do
    quote do
      Scope.put_attribute(__MODULE__, :interfaces, unquote(ifaces))
    end
  end

  @doc """
  Declare an implemented interface for an object.
  """
  defmacro interface(implemented_identifier) do
    quote do
      Scope.put_attribute(
        __MODULE__,
        :interfaces,
        unquote(implemented_identifier),
        accumulate: true
      )
    end
  end

  defmacro interface(identifier, attrs, [do: block]) do
    __scope__(__CALLER__, :interface, identifier, attrs, block)
  end
  defmacro interface(identifier, [do: block]) do
    __scope__(__CALLER__, :interface, identifier, [], block)
  end

  # FIELDS

  defmacro field(identifier, [do: block]) do
    __scope__(__CALLER__, :field, identifier, [], block)
  end
  defmacro field(identifier, attrs) do
    __scope__(__CALLER__, :field, identifier, attrs, nil)
  end

  defmacro field(identifier, attrs, [do: block]) do
    __scope__(__CALLER__, :field, identifier, attrs, block)
  end
  defmacro field(identifier, type, attrs) do
    __scope__(__CALLER__, :field, identifier, Keyword.put(attrs, :type, type),  nil)
  end
  defmacro field(identifier, type, attrs, [do: block]) do
    __scope__(__CALLER__, :field, identifier, Keyword.put(attrs, :type, type), block)
  end

  defmacro resolve(resolver) do
    quote do
      Scope.put_attribute(__MODULE__, :resolve, unquote(resolver))
    end
  end

  defmacro is_type_of(fun) do
    quote do
      Scope.put_attribute(__MODULE__, :is_type_of, unquote(fun))
    end
  end

  # ARGS

  defmacro arg(identifier, type, attrs) do
    __scope__(__CALLER__, :arg, identifier, Keyword.put(attrs, :type, type), nil)
  end
  defmacro arg(identifier, attrs) do
    __scope__(__CALLER__, :arg, identifier, attrs, nil)
  end

  # SCALARS

  defmacro scalar(identifier, attrs, [do: block]) do
    __scope__(__CALLER__, :scalar, identifier, attrs, block)
  end
  defmacro scalar(identifier, [do: block]) do
    __scope__(__CALLER__, :scalar, identifier, [], block)
  end
  defmacro scalar(identifier, attrs) do
    __scope__(__CALLER__, :scalar, identifier, attrs, nil)
  end

  defmacro serialize(raw_fun) do
    fun = Macro.expand(raw_fun, __CALLER__)
    quote do
      Scope.put_attribute(__MODULE__, :serialize, unquote(Macro.escape(fun)))
    end
  end

  defmacro parse(raw_fun) do
    fun = Macro.expand(raw_fun, __CALLER__)
    quote do
      Scope.put_attribute(__MODULE__, :serialize, unquote(Macro.escape(fun)))
    end
  end

  # DIRECTIVES

  defmacro directive(identifier, attrs, [do: block]) do
    __scope__(__CALLER__, :directive, identifier, attrs, block)
  end
  defmacro directive(identifier, [do: block]) do
    __scope__(__CALLER__, :directive, identifier, [], block)
  end

  @doc """
  Declare a directive as operating an a AST node type
  """
  defmacro on(ast_node) do
    quote do
      Scope.put_attribute(
        __MODULE__,
        :on,
        unquote(ast_node),
        accumulate: true
      )
    end
  end

  @doc """
  Calculate the instruction for a directive
  """
  defmacro instruction(fun) do
    fun = Macro.expand(fun, __CALLER__)
    quote do
      Scope.put_attribute(__MODULE__, :instruction, unquote(Macro.escape(fun)))
    end
  end


  # INPUT OBJECTS

  defmacro input_object(identifier, attrs, [do: block]) do
    __scope__(__CALLER__, :input_object, identifier, attrs, block)
  end
  defmacro input_object(identifier, [do: block]) do
    __scope__(__CALLER__, :input_object, identifier, [], block)
  end

  # UNIONS

  defmacro union(identifier, attrs, [do: block]) do
    __scope__(__CALLER__, :union, identifier, attrs, block)
  end
  defmacro union(identifier, [do: block]) do
    __scope__(__CALLER__, :union, identifier, [], block)
  end

  # ENUMS

  defmacro enum(identifier, attrs, [do: block]) do
    __scope__(__CALLER__, :enum, identifier, attrs, block)
  end
  defmacro enum(identifier, [do: block]) do
    __scope__(__CALLER__, :enum, identifier, [], nil)
  end
  defmacro enum(identifier, attrs) do
    __scope__(__CALLER__, :enum, identifier, attrs, nil)
  end

  # UTILITIES

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
    directives = for {ident, _} = naming <- type_module.__absinthe_directives__, into: [] do
      if Enum.member?(type_module.__absinthe_exports__, ident) do
        ast = quote do
          unquote(type_module).__absinthe_directive__(unquote(ident))
        end
        define_directive([naming], ast, opts)
      end
    end
    types ++ directives
  end

  @spec __with_name__(Keyword.t, Type.identifier_t) :: Keyword.t
  @spec __with_name__(Keyword.t, Type.identifier_t, Keyword.t) :: Keyword.t
  defp __with_name__(attrs, identifier, opts \\ []) do
    update_in(attrs, [:name], fn
      nil ->
        Utils.camelize(Atom.to_string(identifier), opts)
      value ->
        value
    end)
  end

  defp define_interface_mapping([{identifier, name}] = naming, interfaces) do
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
      doc = Module.get_attribute(__MODULE__, :doc)
      @absinthe_doc if doc, do: String.strip(doc), else: nil
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

  defp define_directive([{identifier, name}] = naming, ast, opts \\ []) do
    quote do
      @absinthe_doc Module.get_attribute(__MODULE__, :doc)
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

end
