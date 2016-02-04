defmodule Absinthe.Schema.Definition do
  alias Absinthe.Utils

  defmacro __using__(opts) do
    quote do
      import unquote(__MODULE__)
      Module.register_attribute __MODULE__, :absinthe_errors, accumulate: true
      Module.register_attribute __MODULE__, :absinthe_types, accumulate: true
      @before_compile unquote(__MODULE__)
      @after_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(_env) do
    quote do

      def __absinthe_type__(_), do: nil

      @absinthe_type_map Enum.into(@absinthe_types, %{})
      def __absinthe_types__ do
        @absinthe_type_map
      end

      def __absinthe_errors__ do
        @absinthe_errors
      end
    end
  end

  def __after_compile__(env, _bytecode) do
    case env.module.__absinthe_errors__ do
      [] ->
        nil
      problems ->
        raise Absinthe.Schema.Error, problems
    end
  end

  defmacro query(attrs) do
  end

  defmacro mutation(attrs) do
  end

  defmacro object(identifier, blueprint) do
    naming = type_naming(identifier)
    ast = Absinthe.Type.Object.build(naming, expand(blueprint, __CALLER__))
    define_type(naming, ast)
  end

  defmacro interface(identifier, blueprint) do
  end

  defmacro input_object(identifier, blueprint) do
  end

  defmacro union(identifier, blueprint) do
  end

  defp expand(ast, env) do
    Macro.postwalk(ast, fn
      {_, _, _} = node -> Macro.expand(node, env)
      node -> node
    end)
  end

  defp type_naming([{_identifier, _name}] = as_defined) do
    as_defined
  end
  defp type_naming(identifier) do
    [{identifier, Utils.camelize_lower(Atom.to_string(identifier))}]
  end

  defp define_type([{identifier, name}] = naming, ast) do
    quote do
      @absinthe_doc @doc
      type_status = {
        Keyword.has_key?(@absinthe_types, unquote(identifier)),
        Enum.member?(Keyword.values(@absinthe_types), unquote(name))
      }
      if match?({true, _}, type_status) do
        @absinthe_errors %{
          name: :dup_ident,
          location: %{file: __ENV__.file, line: __ENV__.line},
          data: unquote(identifier)
        }
      end
      if match?({_, true}, type_status) do
        @absinthe_errors %{
          name: :dup_name,
          location: %{file: __ENV__.file, line: __ENV__.line},
          data: unquote(name)
        }
      end
      if match?({false, false}, type_status) do
        @absinthe_types {unquote(identifier), unquote(name)}
        def __absinthe_type__(unquote(name)) do
          unquote(ast)
        end
        def __absinthe_type__(unquote(identifier)) do
          unquote(ast)
        end
        def __absinthe_type_ast__(unquote(identifier)) do
          unquote(Macro.escape(ast))
        end
      end
    end
  end

  defmacro deprecate(node, options \\ []) do
    node
  end

  defmacro non_null(type) do
    quote do: %Absinthe.Type.NonNull{of_type: unquote(type)}
  end

  defmacro list_of(type) do
    quote do: %Absinthe.Type.List{of_type: unquote(type)}
  end

end
