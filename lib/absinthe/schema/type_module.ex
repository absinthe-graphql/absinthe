defmodule Absinthe.Schema.TypeModule do
  alias Absinthe.Utils
  alias Absinthe.Type

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

  defmacro object(identifier, attrs, [do: block]) do
    __container__(:object, identifier, attrs, block)
  end
  defmacro object(identifier, [do: block]) do
    __container__(:object, identifier, [], block)
  end

  defp __container__(kind, identifier, attrs, block) do
    quote do
      IO.inspect(container_location: __MODULE__)
      Absinthe.Schema.TypeModule.__open_container__(unquote(kind), __MODULE__, unquote(identifier), unquote(attrs))
      unquote(block)
      Absinthe.Schema.TypeModule.__close_container__(unquote(kind), __MODULE__, unquote(identifier))
    end
  end

  @contain :absinthe_container_stack

  def __open_container__(_, mod, identifier, attrs) do
    stack = __container_stack__(mod)
    Module.put_attribute(mod, @contain, [attrs | stack])
  end

  def __close_container__(:object, mod, identifier) do
    [container | rest] = __container_stack__(mod)
    __container_stack_pop__(mod)
  end

  def __close_container__(:field, mod, identifier) do
    field_container = __container_stack_pop__(mod)
    __container_cons__(mod, :fields, {identifier, field_container})
  end

  def __container_stack_pop__(mod) do
    {container, rest} = __container_stack_split__(mod)
    Module.put_attribute(mod, @contain, rest)
    container
  end

  def __container_stack__(mod) do
    case Module.get_attribute(mod, @contain) do
      nil ->
        Module.put_attribute(mod, @contain, [])
        []
      value ->
        value
    end
  end

  def __container_stack_split__(mod) do
    [container | rest] = __container_stack__(mod)
    {container, rest}
  end

  def __update_container__(mod, fun) do
    {container, rest} = __container_stack_split__(mod)
    updated = fun.(container)
    Module.put_attribute(mod, @contain, [updated | rest])
  end

  defmacro field(identifier, raw_attrs) do
    __container__(:field, identifier, normalize_type_attr(attrs), nil)
  end
  defmacro field(identifier, [do: block]) do
    IO.inspect(identifier: identifier)
    __container__(:field, identifier, [], block)
  end

  defmacro field(identifier, attrs, [do: block]) do
    __container__(:field, identifier, normalize_type_attr(attrs), block)
  end
  defmacro field(identifier, type, attrs) do
    spliced_args = quote do
      [{:type, unquote(type)}, unquote_splicing(attrs)]
    end
    __container__(:field, identifier, spliced_args, nil)
  end
  defmacro field(identifier, type, attrs, [do: block]) do
    spliced_args = quote do
      [{:type, unquote(type)}, unquote_splicing(attrs)]
    end
    __container__(:field, identifier, spliced_args, block)
  end


  defp normalize_type_attr(attrs) when is_list(attrs) do
    attrs
  end
  defp normalize_type_attr(type) do
    [type: type]
  end

  defmacro arg(identifier, type, attrs) do
    spliced_args = quote do: [{:type, unquote(type)}, unquote_splicing(attrs)]
    __arg__(identifier, spliced_args)
  end
  defmacro arg(identifier, attrs) do
    __arg__(identifier, attrs)
  end

  defp __arg__(identifier, attrs) do
    quote do
      Absinthe.Schema.TypeModule.__container_cons__(__MODULE__, :args, unquote(attrs))
    end
  end

  defmacro resolve(resolver) do
    quote do
      Absinthe.Schema.TypeModule.__container_put__(__MODULE__, :resolve, unquote(resolver))
    end
  end

  def __container_put__(mod, key, value) do
    Absinthe.Schema.TypeModule.__update_container__(mod, fn
      container ->
        Keyword.put(container, key, value)
    end)
  end

  def __container_cons__(mod, key, value) do
    Absinthe.Schema.TypeModule.__update_container__(mod, fn
      container ->
        {_, updated} = get_and_update_in(container,
                                       [key],
                                       &{&1, [value | (&1 || [])]})
        updated
    end)
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
      Absinthe.Schema.TypeModule.__container_cons__(
        __MODULE__,
        :interfaces,
        unquote(implemented_identifier)
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

  defmacro enum(identifier, attrs, [do: block]) do
  end
  defmacro enum(identifier, [do: block]) do
    enum(identifier, [], [do: block])
  end






  defmacro import_types(type_module_ast, opts_ast \\ []) do
    opts = Macro.expand(opts_ast, __CALLER__)
    type_module = Macro.expand(type_module_ast, __CALLER__)
    types = for {ident, _} = naming <- type_module.__absinthe_types__, into: [] do
      if Enum.member?(type_module.__absinthe_exports__, ident) do
        ast = quote do
          unquote(type_module).__absinthe_type__(unquote(ident))
        end
        define_type([naming], ast, opts)
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

  @spec name_attr(Type.identifier_t, Keyword.t) :: {:name, binary}
  defp name_attr(identifier, attrs) do
    {
      :name,
      Keyword.get(attrs, :name, Utils.camelize(Atom.to_string(identifier)))
    }
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

  defp define_type([{identifier, name}] = naming, ast, opts \\ []) do
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

  defmacro deprecate(node, options \\ []) do
    quote do
      [unquote_splicing(node), deprecation: %Type.Deprecation{unquote_splicing(options)}]
    end
  end

  defmacro non_null(type) do
    quote do: %Absinthe.Type.NonNull{of_type: unquote(type)}
  end

  defmacro list_of(type) do
    quote do: %Absinthe.Type.List{of_type: unquote(type)}
  end

end
