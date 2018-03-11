defmodule Absinthe.Schema do
  alias Absinthe.Type
  alias Absinthe.Language
  alias __MODULE__

  @type t :: module

  defmacro __using__(_opt) do
    quote do
      use Absinthe.Schema.Notation.Experimental
      @after_compile unquote(__MODULE__)

      defdelegate __absinthe_type__(name), to: __MODULE__.Compiled

      def __absinthe_lookup__(name) do
        __absinthe_type__(name)
      end

      @doc false
      def middleware(middleware, _field, _object) do
        middleware
      end

      @doc false
      def plugins do
        Absinthe.Plugin.defaults()
      end

      @doc false
      def context(context) do
        context
      end

      defoverridable(context: 1, middleware: 3)
    end
  end

  def pipeline(opts \\ []) do
    alias Absinthe.Phase

    [
      Phase.Validation.KnownTypeNames,
      Phase.Validation.KnownDirectives,
      {Phase.Schema.Compile, opts}
    ]
  end

  def __after_compile__(env, _) do
    blueprint = env.module.__absinthe_blueprint__
    pipeline = pipeline(module: env.module)

    Absinthe.Pipeline.run(blueprint, pipeline)
    []
  end

  ### Helpers

  @doc """
  Run the introspection query on a schema.

  Convenience function.
  """
  @spec introspect(schema :: t, opts :: Absinthe.run_opts()) :: Absinthe.run_result()
  def introspect(schema, opts \\ []) do
    [:code.priv_dir(:absinthe), "graphql", "introspection.graphql"]
    |> Path.join()
    |> File.read!()
    |> Absinthe.run(schema, opts)
  end

  @doc """
  Replace the default middleware

  ## Examples
  Replace the default for all fields with a string lookup instead of an atom lookup:
  ```
  def middleware(middleware, field, object) do
    new_middleware = {Absinthe.Middleware.MapGet, to_string(field.identifier)}
    middleware
    |> Absinthe.Schema.replace_default(new_middleware, field, object)
  end
  ```
  """
  def replace_default(middleware_list, new_middleware, %{identifier: identifer}, _object) do
    Enum.map(middleware_list, fn middleware ->
      case middleware do
        {Absinthe.Middleware.MapGet, ^identifer} ->
          new_middleware

        middleware ->
          middleware
      end
    end)
  end

  def lookup_directive(schema, name) do
    schema.__absinthe_directive__(name)
  end

  def lookup_type(schema, type, options \\ [unwrap: true]) do
    cond do
      is_atom(type) ->
        schema.__absinthe_lookup__(type)

      is_binary(type) ->
        schema.__absinthe_lookup__(type)

      Type.wrapped?(type) ->
        if Keyword.get(options, :unwrap) do
          lookup_type(schema, type |> Type.unwrap())
        else
          type
        end

      true ->
        type
    end
  end

  @doc """
  Get all concrete types for union, interface, or object
  """
  @spec concrete_types(t, Type.t()) :: [Type.t()]
  def concrete_types(schema, %Type.Union{} = type) do
    Enum.map(type.types, &lookup_type(schema, &1))
  end

  def concrete_types(schema, %Type.Interface{} = type) do
    implementors(schema, type)
  end

  def concrete_types(_, %Type.Object{} = type) do
    [type]
  end

  def concrete_types(_, type) do
    [type]
  end

  @doc """
  Get all types that are used by an operation
  """
  @spec used_types(t) :: [Type.t()]
  def used_types(schema) do
    [:query, :mutation, :subscription]
    |> Enum.map(&lookup_type(schema, &1))
    |> Enum.concat(directives(schema))
    |> Enum.filter(&(!is_nil(&1)))
    |> Enum.flat_map(&Type.referenced_types(&1, schema))
    |> MapSet.new()
    |> Enum.map(&Schema.lookup_type(schema, &1))
  end

  @doc """
  List all directives on a schema
  """
  @spec directives(t) :: [Type.Directive.t()]
  def directives(schema) do
    schema.__absinthe_directives__
    |> Map.keys()
    |> Enum.map(&lookup_directive(schema, &1))
  end

  @doc """
  List all implementors of an interface on a schema
  """
  @spec implementors(t, Type.identifier_t() | Type.Interface.t()) :: [Type.Object.t()]
  def implementors(schema, ident) when is_atom(ident) do
    schema.__absinthe_interface_implementors__
    |> Map.get(ident, [])
    |> Enum.map(&lookup_type(schema, &1))
  end

  def implementors(schema, %Type.Interface{} = iface) do
    implementors(schema, iface.__reference__.identifier)
  end

  @doc false
  @spec type_from_ast(t, Language.type_reference_t()) :: Absinthe.Type.t() | nil
  def type_from_ast(schema, %Language.NonNullType{type: inner_type}) do
    case type_from_ast(schema, inner_type) do
      nil -> nil
      type -> %Type.NonNull{of_type: type}
    end
  end

  def type_from_ast(schema, %Language.ListType{type: inner_type}) do
    case type_from_ast(schema, inner_type) do
      nil -> nil
      type -> %Type.List{of_type: type}
    end
  end

  def type_from_ast(schema, ast_type) do
    Schema.types(schema)
    |> Enum.find(fn %{name: name} ->
      name == ast_type.name
    end)
  end
end
