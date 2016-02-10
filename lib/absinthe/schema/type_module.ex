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
          {_, result} = Map.get_and_update(acc, iface, fn
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

  defmacro object(identifier, blueprint, opts \\ []) do
    naming = type_naming(identifier)
    expanded = expand(blueprint, __CALLER__)
    ast = Absinthe.Type.Object.build(naming, expanded)
    [
      define_type(naming, ast, opts),
      define_interface_mapping(naming, expanded[:interfaces] || [])
    ]
  end

  defmacro directive(identifier, blueprint, opts \\ []) when is_atom(identifier) do
    naming = [{identifier, Atom.to_string(identifier)}]
    ast = Absinthe.Type.Directive.build(naming, expand(blueprint, __CALLER__))
    define_directive(naming, ast, opts)
  end

  defmacro scalar(identifier, blueprint, opts \\ []) do
    naming = type_naming(identifier)
    ast = Absinthe.Type.Scalar.build(naming, expand(blueprint, __CALLER__))
    define_type(naming, ast, opts)
  end

  defmacro interface(identifier, blueprint, opts \\ []) do
    naming = type_naming(identifier)
    expanded = expand(blueprint, __CALLER__)
    ast = Absinthe.Type.Interface.build(naming, expanded)
    define_type(naming, ast, opts)
  end

  defmacro input_object(identifier, blueprint, opts \\ []) do
    naming = type_naming(identifier)
    ast = Absinthe.Type.InputObject.build(naming, expand(blueprint, __CALLER__))
    define_type(naming, ast, opts)
  end

  defmacro union(identifier, blueprint, opts \\ []) do
    naming = type_naming(identifier)
    ast = Absinthe.Type.Union.build(naming, expand(blueprint, __CALLER__))
    define_type(naming, ast, opts)
  end

  defmacro enum(identifier, blueprint, opts \\ []) do
    naming = type_naming(identifier)
    ast = Absinthe.Type.Enum.build(naming, expand(blueprint, __CALLER__))
    define_type(naming, ast, opts)
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

  @expand [:list_of, :deprecate, :non_null]
  def expand(ast, env) do
    Macro.postwalk(ast, fn
      {thing, _, _} = node when thing in @expand -> Macro.expand(node, env)
      node -> node
    end)
  end

  defp type_naming([{_identifier, _name}] = as_defined) do
    as_defined
  end
  defp type_naming(identifier) do
    [{identifier, Utils.camelize(Atom.to_string(identifier))}]
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
      @absinthe_doc Module.get_attribute(__MODULE__, :doc)
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
