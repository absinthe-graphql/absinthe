defmodule Absinthe.Schema.Notation do
  alias Absinthe.Utils
  alias Absinthe.Type
  alias Absinthe.Schema.Notation.Scopes

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

  def __scope__(kind, identifier, attrs, block) do
    quote do
      Absinthe.Schema.Notation.__open_scope__(unquote(kind), __MODULE__, unquote(identifier), unquote(attrs))
      unquote(block)
      Absinthe.Schema.Notation.__close_scope__(unquote(kind), __MODULE__, unquote(identifier))
    end
  end

  def __prepare_attrs__(caller, type, attrs) do
    __do_prepare_attrs__(caller, [{:type, type} | attrs])
  end
  def __prepare_attrs__(caller, attrs) when is_list(attrs) do
    __do_prepare_attrs__(caller, attrs)
  end
  def __prepare_attrs__(caller, type) do
    __do_prepare_attrs__(caller, [type: type])
  end
  defp __do_prepare_attrs__(caller, attrs) do
    attrs
    |> Macro.expand(caller)
    |> Macro.escape
  end

  def __open_scope__(_, mod, identifier, attrs) do
    Scopes.open(mod, attrs)
  end

  def __close_scope__(:object, mod, identifier) do
    attrs = Scopes.close(mod) |> add_name(identifier)
    type_obj = Type.Object.build(identifier, attrs)
    define_type({identifier, attrs[:name]}, type_obj)
  end

  def __close_scope__(:field, mod, identifier) do
    attrs = Scopes.close(mod) |> add_name(identifier, lower: true)
    Scopes.put_attribute(mod, :fields, {identifier, attrs}, accumulate: true)
    nil
  end
  def __close_scope__(_, mod, identifier) do
    Scopes.close(mod)
    nil
  end

  defmacro object(identifier, attrs, [do: block]) do
    __scope__(:object, identifier, attrs, block)
  end
  defmacro object(identifier, [do: block]) do
    __scope__(:object, identifier, [], block)
  end

  defmacro field(identifier, raw_attrs) do
    attrs = __prepare_attrs__(__CALLER__, raw_attrs)
    __scope__(:field, identifier, attrs, nil)
  end
  defmacro field(identifier, [do: block]) do
    __scope__(:field, identifier, [], block)
  end

  defmacro field(identifier, raw_attrs, [do: block]) do
    attrs = __prepare_attrs__(__CALLER__, raw_attrs)
    __scope__(:field, identifier, attrs, block)
  end
  defmacro field(identifier, type, raw_attrs) do
    attrs = __prepare_attrs__(__CALLER__, type, raw_attrs)
    __scope__(:field, identifier, attrs, nil)
  end
  defmacro field(identifier, type, raw_attrs, [do: block]) do
    attrs = __prepare_attrs__(__CALLER__, type, raw_attrs)
    __scope__(:field, identifier, attrs, block)
  end

  defmacro arg(identifier, type, raw_attrs) do
    attrs = __prepare_attrs__(__CALLER__, type, raw_attrs)
    __arg__(identifier, attrs)
  end
  defmacro arg(identifier, raw_attrs) do
    attrs = __prepare_attrs__(__CALLER__, raw_attrs)
    __arg__(identifier, attrs)
  end

  defp __arg__(identifier, attrs) do
    quote do
      Scopes.put_attribute(__MODULE__, :args, unquote(attrs), accumulate: true)
    end
  end

  defmacro resolve(resolver) do
    quote do
      Scopes.put_attribute(__MODULE__, :resolve, unquote(resolver))
    end
  end

  defmacro is_type_of(fun) do
    quote do
      Scopes.put_attribute(__MODULE__, :is_type_of, unquote(fun))
    end
  end

  defmacro interfaces(ifaces) do
    quote do
      Scopes.put_attribute(__MODULE__, :interfaces, unquote(ifaces))
    end
  end

  defmacro directive(identifier, attrs, [do: block]) do
  end
  defmacro directive(identifier, [do: block]) do
    directive(identifier, [], [do: block])
  end

  defmacro scalar(identifier, attrs, [do: block]) do
  end
  defmacro scalar(identifier, [do: block]) do
    scalar(identifier, [], [do: block])
  end

  defmacro interface(implemented_identifier) do
    quote do
      Scopes.put_attribute(
        __MODULE__,
        :interfaces,
        unquote(implemented_identifier),
        accumulate: true
      )
    end
  end

  defmacro interface(identifier, attrs, [do: block]) do
  end
  defmacro interface(identifier, [do: block]) do
    interface(identifier, [], [do: block])
  end

  defmacro input_object(identifier, attrs, [do: block]) do
  end
  defmacro input_object(identifier, [do: block]) do
    input_object(identifier, [], [do: block])
  end

  defmacro union(identifier, attrs, [do: block]) do
  end
  defmacro union(identifier, [do: block]) do
    input_object(identifier, [], [do: block])
  end

  defmacro enum(identifier, raw_attrs, [do: block]) do
    attrs = __prepare_attrs__(__CALLER__, raw_attrs)
    __scope__(:enum, identifier, attrs, block)
  end
  defmacro enum(identifier, [do: block]) do
    __scope__(:enum, identifier, [], nil)
  end
  defmacro enum(identifier, raw_attrs) do
    attrs = __prepare_attrs__(__CALLER__, raw_attrs)
    __scope__(:enum, identifier, attrs, nil)
  end

  defmacro import_types(type_module_ast, opts_ast \\ []) do
    opts = Macro.expand(opts_ast, __CALLER__)
    type_module = Macro.expand(type_module_ast, __CALLER__)
    types = for {ident, _} = naming <- type_module.__absinthe_types__, into: [] do
      if Enum.member?(type_module.__absinthe_exports__, ident) do
        ast = quote do
          unquote(type_module).__absinthe_type__(unquote(ident))
        end
        define_type(naming, ast, opts)
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

  @spec add_name(Keyword.t, Type.identifier_t) :: Keyword.t
  @spec add_name(Keyword.t, Type.identifier_t, Keyword.t) :: Keyword.t
  defp add_name(attrs, identifier, opts \\ []) do
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

  defp define_type({identifier, name}, ast, opts \\ []) do
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
    quote do: %Absinthe.Type.NonNull{of_type: unquote(type)}
  end

  defmacro list_of(type) do
    quote do: %Absinthe.Type.List{of_type: unquote(type)}
  end

end
