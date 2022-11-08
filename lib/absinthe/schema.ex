defmodule Absinthe.Schema do
  alias Absinthe.Type
  alias Absinthe.Utils
  alias __MODULE__

  @type t :: module

  @moduledoc """
  Build GraphQL Schemas

  ## Custom Schema Manipulation (in progress)
  In Absinthe 1.5 and up schemas are built using the same process by which queries are
  executed. All the macros in this module and in `Notation` build up an intermediary tree of structs in the
  `%Absinthe.Blueprint{}` namespace, which we generally call "Blueprint structs".

  At the top you've got a `%Blueprint{}` struct which holds onto some schema
  definitions that look a bit like this:

  ```
  %Blueprint.Schema.SchemaDefinition{
    type_definitions: [
      %Blueprint.Schema.ObjectTypeDefinition{identifier: :query, ...},
      %Blueprint.Schema.ObjectTypeDefinition{identifier: :mutation, ...},
      %Blueprint.Schema.ObjectTypeDefinition{identifier: :user, ...},
      %Blueprint.Schema.EnumTypeDefinition{identifier: :sort_order, ...},
    ]
  }
  ```

  You can see what your schema's blueprint looks like by calling
  `__absinthe_blueprint__` on any schema or type definition module.

  ```
  defmodule MyAppWeb.Schema do
    use Absinthe.Schema

    query do

    end
  end

  > MyAppWeb.Schema.__absinthe_blueprint__
  #=> %Absinthe.Blueprint{...}
  ```

  These blueprints are manipulated by phases, which validate and ultimately
  construct a schema. This pipeline of phases you can hook into like you do for
  queries.

  ```
  defmodule MyAppWeb.Schema do
    use Absinthe.Schema

    @pipeline_modifier MyAppWeb.CustomSchemaPhase

    query do

    end

  end

  defmodule MyAppWeb.CustomSchemaPhase do
    alias Absinthe.{Phase, Pipeline, Blueprint}

    # Add this module to the pipeline of phases
    # to run on the schema
    def pipeline(pipeline) do
      Pipeline.insert_after(pipeline, Phase.Schema.TypeImports, __MODULE__)
    end

    # Here's the blueprint of the schema, do whatever you want with it.
    def run(blueprint, _) do
      {:ok, blueprint}
    end
  end
  ```

  The blueprint structs are pretty complex, but if you ever want to figure out
  how to construct something in blueprints you can always just create the thing
  in the normal AST and then look at the output. Let's see what interfaces look
  like for example:

  ```
  defmodule Foo do
    use Absinthe.Schema.Notation

    interface :named do
      field :name, :string
    end
  end

  Foo.__absinthe_blueprint__ #=> ...
  ```
  """

  Module.register_attribute(__MODULE__, :placement, accumulate: true)

  defmacro __using__(opts) do
    Module.register_attribute(__CALLER__.module, :pipeline_modifier,
      accumulate: true,
      persist: true
    )

    Module.register_attribute(__CALLER__.module, :prototype_schema, persist: true)

    {use_spec_compliant_int_scalar, opts} =
      Keyword.pop(opts, :use_spec_compliant_int_scalar, false)

    if use_spec_compliant_int_scalar do
      Module.put_attribute(
        __CALLER__.module,
        :pipeline_modifier,
        Absinthe.Phase.Schema.SpecCompliantInt
      )
    end

    opts =
      Keyword.merge(opts,
        except: [
          import_types: 1,
          import_types: 2,
          import_type_extensions: 1,
          import_type_extensions: 2,
          import_directives: 1,
          import_directives: 2
        ]
      )

    quote do
      use Absinthe.Schema.Notation, unquote(opts)
      import unquote(__MODULE__), only: :macros

      @after_compile unquote(__MODULE__)
      @before_compile unquote(__MODULE__)
      @prototype_schema Absinthe.Schema.Prototype

      @schema_provider Absinthe.Schema.Compiled

      def __absinthe_lookup__(name) do
        __absinthe_type__(name)
      end

      @behaviour Absinthe.Schema

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

      @doc false
      def hydrate(_node, _ancestors) do
        []
      end

      defoverridable(context: 1, middleware: 3, plugins: 0, hydrate: 2)
    end
  end

  def child_spec(schema) do
    %{
      id: {__MODULE__, schema},
      start: {__MODULE__.Manager, :start_link, [schema]},
      type: :worker
    }
  end

  @object_type Absinthe.Blueprint.Schema.ObjectTypeDefinition

  @default_query_name "RootQueryType"
  @placement {:query, [toplevel: true, extend: true]}
  @doc """
  Defines a root Query object
  """
  @doc group: :notation
  defmacro query(raw_attrs \\ [name: @default_query_name], do: block) do
    record_query(__CALLER__, raw_attrs, block)
  end

  defp record_query(env, raw_attrs, block) do
    attrs =
      raw_attrs
      |> Keyword.put_new(:name, @default_query_name)

    env
    |> Absinthe.Schema.Notation.recordable!(:query, @placement[:query])
    |> Absinthe.Schema.Notation.record!(@object_type, :query, attrs, block)
  end

  @default_mutation_name "RootMutationType"
  @placement {:mutation, [toplevel: true, extend: true]}
  @doc """
  Defines a root Mutation object

  ```
  mutation do
    field :create_user, :user do
      arg :name, non_null(:string)
      arg :email, non_null(:string)

      resolve &MyApp.Web.BlogResolvers.create_user/2
    end
  end
  ```
  """
  @doc group: :notation
  defmacro mutation(raw_attrs \\ [name: @default_mutation_name], do: block) do
    record_mutation(__CALLER__, raw_attrs, block)
  end

  defp record_mutation(env, raw_attrs, block) do
    attrs =
      raw_attrs
      |> Keyword.put_new(:name, @default_mutation_name)

    env
    |> Absinthe.Schema.Notation.recordable!(:mutation, @placement[:mutation])
    |> Absinthe.Schema.Notation.record!(@object_type, :mutation, attrs, block)
  end

  @default_subscription_name "RootSubscriptionType"
  @placement {:subscription, [toplevel: true, extend: true]}
  @doc """
  Defines a root Subscription object

  Subscriptions in GraphQL let a client submit a document to the server that
  outlines what data they want to receive in the event of particular updates.

  For a full walk through of how to setup your project with subscriptions and
  `Phoenix` see the `Absinthe.Phoenix` project moduledoc.

  When you push a mutation, you can have selections on that mutation result
  to get back data you need, IE

  ```graphql
  mutation {
    createUser(accountId: 1, name: "bob") {
      id
      account { name }
    }
  }
  ```

  However, what if you want to know when OTHER people create a new user, so that
  your UI can update as well. This is the point of subscriptions.

  ```graphql
  subscription {
    newUsers {
      id
      account { name }
    }
  }
  ```

  The job of the subscription macros then is to give you the tools to connect
  subscription documents with the values that will drive them. In the last example
  we would get all users for all accounts, but you could imagine wanting just
  `newUsers(accountId: 2)`.

  In your schema you articulate the interests of a subscription via the `config`
  macro:

  ```
  subscription do
    field :new_users, :user do
      arg :account_id, non_null(:id)

      config fn args, _info ->
        {:ok, topic: args.account_id}
      end
    end
  end
  ```
  The topic can be any term. You can broadcast a value manually to this subscription
  by doing

  ```
  Absinthe.Subscription.publish(pubsub, user, [new_users: user.account_id])
  ```

  It's pretty common to want to associate particular mutations as the triggers
  for one or more subscriptions, so Absinthe provides some macros to help with
  that too.

  ```
  subscription do
    field :new_users, :user do
      arg :account_id, non_null(:id)

      config fn args, _info ->
        {:ok, topic: args.account_id}
      end

      trigger :create_user, topic: fn user ->
        user.account_id
      end
    end
  end
  ```

  The idea with a trigger is that it takes either a single mutation `:create_user`
  or a list of mutations `[:create_user, :blah_user, ...]` and a topic function.
  This function returns a value that is used to lookup documents on the basis of
  the topic they returned from the `config` macro.

  Note that a subscription field can have `trigger` as many trigger blocks as you
  need, in the event that different groups of mutations return different results
  that require different topic functions.
  """
  @doc group: :notation
  defmacro subscription(raw_attrs \\ [name: @default_subscription_name], do: block) do
    record_subscription(__CALLER__, raw_attrs, block)
  end

  defp record_subscription(env, raw_attrs, block) do
    attrs =
      raw_attrs
      |> Keyword.put_new(:name, @default_subscription_name)

    env
    |> Absinthe.Schema.Notation.recordable!(:subscription, @placement[:subscription])
    |> Absinthe.Schema.Notation.record!(@object_type, :subscription, attrs, block)
  end

  @placement {:import_types, [toplevel: true]}
  @doc """
  Import types from another module

  Very frequently your schema module will simply have the `query` and `mutation`
  blocks, and you'll want to break out your other types into other modules. This
  macro imports those types for use the current module.

  To selectively import types you can use the `:only` and `:except` opts.

  ## Placement

  #{Utils.placement_docs(@placement)}

  ## Examples
  ```
  import_types MyApp.Schema.Types

  import_types MyApp.Schema.Types.{TypesA, TypesB}

  import_types MyApp.Schema.Types, only: [:foo]

  import_types MyApp.Schema.Types, except: [:bar]
  ```
  """
  @doc group: :notation
  defmacro import_types(type_module_ast, opts \\ []) do
    env = __CALLER__

    type_module_ast
    |> Macro.expand(env)
    |> do_import_types(env, opts)
  end

  defp do_import_types({{:., _, [{:__MODULE__, _, _}, :{}]}, _, modules_ast_list}, env, opts) do
    for {_, _, leaf} <- modules_ast_list do
      type_module = Module.concat([env.module | leaf])

      do_import_types(type_module, env, opts)
    end
  end

  defp do_import_types(
         {{:., _, [{:__aliases__, _, [{:__MODULE__, _, _} | tail]}, :{}]}, _, modules_ast_list},
         env,
         opts
       ) do
    root_module = Module.concat([env.module | tail])

    for {_, _, leaf} <- modules_ast_list do
      type_module = Module.concat([root_module | leaf])

      do_import_types(type_module, env, opts)
    end
  end

  defp do_import_types({{:., _, [{:__aliases__, _, root}, :{}]}, _, modules_ast_list}, env, opts) do
    root_module = Module.concat(root)
    root_module_with_alias = Keyword.get(env.aliases, root_module, root_module)

    for {_, _, leaf} <- modules_ast_list do
      type_module = Module.concat([root_module_with_alias | leaf])

      do_import_types(type_module, env, opts)
    end
  end

  defp do_import_types(module, env, opts) do
    Module.put_attribute(env.module, :__absinthe_type_imports__, [
      {module, opts} | Module.get_attribute(env.module, :__absinthe_type_imports__) || []
    ])

    []
  end

  @placement {:import_directives, [toplevel: true]}
  @doc """
  Import directives from another module

  To selectively import directives you can use the `:only` and `:except` opts.

  ## Placement
  #{Utils.placement_docs(@placement)}

  ## Examples
  ```
  import_directives MyApp.Schema.Directives

  import_directives MyApp.Schema.Directives.{DirectivesA, DirectivesB}

  import_directives MyApp.Schema.Directives, only: [:foo]

  import_directives MyApp.Schema.Directives, except: [:bar]
  ```
  """
  @doc group: :notation
  defmacro import_directives(type_module_ast, opts \\ []) do
    env = __CALLER__

    type_module_ast
    |> Macro.expand(env)
    |> do_import_directives(env, opts)
  end

  defp do_import_directives({{:., _, [{:__MODULE__, _, _}, :{}]}, _, modules_ast_list}, env, opts) do
    for {_, _, leaf} <- modules_ast_list do
      type_module = Module.concat([env.module | leaf])

      do_import_directives(type_module, env, opts)
    end
  end

  defp do_import_directives(
         {{:., _, [{:__aliases__, _, [{:__MODULE__, _, _} | tail]}, :{}]}, _, modules_ast_list},
         env,
         opts
       ) do
    root_module = Module.concat([env.module | tail])

    for {_, _, leaf} <- modules_ast_list do
      type_module = Module.concat([root_module | leaf])

      do_import_directives(type_module, env, opts)
    end
  end

  defp do_import_directives(
         {{:., _, [{:__aliases__, _, root}, :{}]}, _, modules_ast_list},
         env,
         opts
       ) do
    root_module = Module.concat(root)
    root_module_with_alias = Keyword.get(env.aliases, root_module, root_module)

    for {_, _, leaf} <- modules_ast_list do
      type_module = Module.concat([root_module_with_alias | leaf])

      do_import_directives(type_module, env, opts)
    end
  end

  defp do_import_directives(module, env, opts) do
    Module.put_attribute(env.module, :__absinthe_directive_imports__, [
      {module, opts} | Module.get_attribute(env.module, :__absinthe_directive_imports__) || []
    ])

    []
  end

  defp do_import_type_extensions(
         {{:., _, [{:__MODULE__, _, _}, :{}]}, _, modules_ast_list},
         env,
         opts
       ) do
    for {_, _, leaf} <- modules_ast_list do
      type_module = Module.concat([env.module | leaf])

      do_import_type_extensions(type_module, env, opts)
    end
  end

  defp do_import_type_extensions(
         {{:., _, [{:__aliases__, _, [{:__MODULE__, _, _} | tail]}, :{}]}, _, modules_ast_list},
         env,
         opts
       ) do
    root_module = Module.concat([env.module | tail])

    for {_, _, leaf} <- modules_ast_list do
      type_module = Module.concat([root_module | leaf])

      do_import_type_extensions(type_module, env, opts)
    end
  end

  defp do_import_type_extensions(
         {{:., _, [{:__aliases__, _, root}, :{}]}, _, modules_ast_list},
         env,
         opts
       ) do
    root_module = Module.concat(root)
    root_module_with_alias = Keyword.get(env.aliases, root_module, root_module)

    for {_, _, leaf} <- modules_ast_list do
      type_module = Module.concat([root_module_with_alias | leaf])

      do_import_type_extensions(type_module, env, opts)
    end
  end

  defp do_import_type_extensions(module, env, opts) do
    Module.put_attribute(env.module, :__absinthe_type_extension_imports__, [
      {module, opts}
      | Module.get_attribute(env.module, :__absinthe_type_extension_imports__) || []
    ])

    []
  end

  @placement {:import_type_extensions, [toplevel: true]}
  @doc """
  Import type_extensions from another module

  To selectively import type_extensions you can use the `:only` and `:except` opts.

  ## Placement
  #{Utils.placement_docs(@placement)}

  ## Examples
  ```
  import_type_extensions MyApp.Schema.TypeExtensions

  import_type_extensions MyApp.Schema.TypeExtensions.{TypeExtensionsA, TypeExtensionsB}

  import_type_extensions MyApp.Schema.TypeExtensions, only: [:foo]

  import_type_extensions MyApp.Schema.TypeExtensions, except: [:bar]
  ```
  """
  @doc group: :notation
  defmacro import_type_extensions(type_module_ast, opts \\ []) do
    env = __CALLER__

    type_module_ast
    |> Macro.expand(env)
    |> do_import_type_extensions(env, opts)
  end

  @placement {:schema, [toplevel: true, extend: true]}
  @doc """
  Declare a schema

  Optional declaration of the schema. Useful if you want to add directives
  to your schema declaration

  ## Placement

  #{Utils.placement_docs(@placement)}

  ## Examples

  ```
  schema do
    directive :feature
    field :query, :query
    # ...
  end
  ```
  """
  @doc group: :notation
  defmacro schema(do: block) do
    __CALLER__
    |> Absinthe.Schema.Notation.recordable!(:schema, @placement[:schema])
    |> Absinthe.Schema.Notation.record_schema!(block)
  end

  defmacro __before_compile__(_) do
    quote do
      @doc false
      def __absinthe_pipeline_modifiers__ do
        [@schema_provider] ++ @pipeline_modifier
      end

      def __absinthe_schema_provider__ do
        @schema_provider
      end

      def __absinthe_type__(name) do
        @schema_provider.__absinthe_type__(__MODULE__, name)
      end

      def __absinthe_directive__(name) do
        @schema_provider.__absinthe_directive__(__MODULE__, name)
      end

      def __absinthe_types__() do
        @schema_provider.__absinthe_types__(__MODULE__)
      end

      def __absinthe_types__(group) do
        @schema_provider.__absinthe_types__(__MODULE__, group)
      end

      def __absinthe_directives__() do
        @schema_provider.__absinthe_directives__(__MODULE__)
      end

      def __absinthe_interface_implementors__() do
        @schema_provider.__absinthe_interface_implementors__(__MODULE__)
      end

      def __absinthe_schema_declaration__() do
        @schema_provider.__absinthe_schema_declaration__(__MODULE__)
      end

      def __absinthe_prototype_schema__() do
        @prototype_schema
      end
    end
  end

  @spec apply_modifiers(Absinthe.Pipeline.t(), t) :: Absinthe.Pipeline.t()
  def apply_modifiers(pipeline, schema) do
    Enum.reduce(schema.__absinthe_pipeline_modifiers__, pipeline, fn
      {module, function}, pipeline ->
        apply(module, function, [pipeline])

      module, pipeline ->
        module.pipeline(pipeline)
    end)
  end

  def __after_compile__(env, _) do
    prototype_schema =
      env.module
      |> Module.get_attribute(:prototype_schema)

    pipeline =
      env.module
      |> Absinthe.Pipeline.for_schema(prototype_schema: prototype_schema)
      |> apply_modifiers(env.module)

    env.module.__absinthe_blueprint__
    |> Absinthe.Pipeline.run(pipeline)
    |> case do
      {:ok, _, _} ->
        []

      {:error, errors, _} ->
        raise Absinthe.Schema.Error, phase_errors: List.wrap(errors)
    end
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
  Replace the default middleware.

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
  def replace_default(middleware_list, new_middleware, %{identifier: identifier}, _object) do
    Enum.map(middleware_list, fn middleware ->
      case middleware do
        {Absinthe.Middleware.MapGet, ^identifier} ->
          new_middleware

        middleware ->
          middleware
      end
    end)
  end

  @doc """
  Used to define the list of plugins to run before and after resolution.

  Plugins are modules that implement the `Absinthe.Plugin` behaviour. These modules
  have the opportunity to run callbacks before and after the resolution of the entire
  document, and have access to the resolution accumulator.

  Plugins must be specified by the schema, so that Absinthe can make sure they are
  all given a chance to run prior to resolution.
  """
  @callback plugins() :: [Absinthe.Plugin.t()]

  @doc """
  Used to apply middleware on all or a group of fields based on pattern matching.

  It is passed the existing middleware for a field, the field itself, and the object
  that the field is a part of.

  ## Examples

  Adding a `HandleChangesetError` middleware only to mutations:

  ```
  # if it's a field for the mutation object, add this middleware to the end
  def middleware(middleware, _field, %{identifier: :mutation}) do
    middleware ++ [MyAppWeb.Middleware.HandleChangesetErrors]
  end

  # if it's any other object keep things as is
  def middleware(middleware, _field, _object), do: middleware
  ```
  """
  @callback middleware([Absinthe.Middleware.spec(), ...], Type.Field.t(), Type.Object.t()) :: [
              Absinthe.Middleware.spec(),
              ...
            ]

  @doc """
  Used to set some values in the context that it may need in order to run.

  ## Examples

  Setup dataloader:

  ```
  def context(context) do
    loader =
      Dataloader.new
      |> Dataloader.add_source(Blog, Blog.data())

      Map.put(context, :loader, loader)
  end
  ```
  """
  @callback context(map) :: map

  @doc """
  Used to hydrate the schema with dynamic attributes.

  While this is normally used to add resolvers, etc, to schemas
  defined using `import_sdl/1` and `import_sdl/2`, it can also be
  used in schemas defined using other macros.

  The function is passed the blueprint definition node as the first
  argument and its ancestors in a list (with its parent node as the
  head) as its second argument.

  See the `Absinthe.Phase.Schema.Hydrate` implementation of
  `Absinthe.Schema.Hydrator` callbacks to see what hydration
  values can be returned.

  ## Examples

  Add a resolver for a field:

  ```
  def hydrate(%Absinthe.Blueprint.Schema.FieldDefinition{identifier: :health}, [%Absinthe.Blueprint.Schema.ObjectTypeDefinition{identifier: :query} | _]) do
    {:resolve, &__MODULE__.health/3}
  end

  # Resolver implementation:
  def health(_, _, _), do: {:ok, "alive!"}
  ```

  Note that the values provided must be macro-escapable; notably, anonymous functions cannot
  be used.

  You can, of course, omit the struct names for brevity:

  ```
  def hydrate(%{identifier: :health}, [%{identifier: :query} | _]) do
    {:resolve, &__MODULE__.health/3}
  end
  ```

  Add a description to a type:

  ```
  def hydrate(%Absinthe.Blueprint.Schema.ObjectTypeDefinition{identifier: :user}, _) do
    {:description, "A user"}
  end
  ```

  If you define `hydrate/2`, don't forget to include a fallback, e.g.:

  ```
  def hydrate(_node, _ancestors), do: []
  ```
  """
  @callback hydrate(
              node :: Absinthe.Blueprint.Schema.t(),
              ancestors :: [Absinthe.Blueprint.Schema.t()]
            ) :: Absinthe.Schema.Hydrator.hydration()

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

  def schema_declaration(schema) do
    schema.__absinthe_schema_declaration__()
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
  @deprecated "Use Absinthe.Schema.referenced_types/1 instead"
  @spec used_types(t) :: [Type.t()]
  def used_types(schema) do
    referenced_types(schema)
  end

  @doc """
  Get all types that are referenced by an operation
  """
  @spec referenced_types(t) :: [Type.t()]
  def referenced_types(schema) do
    schema
    |> Schema.types()
    |> Enum.filter(&(!Type.introspection?(&1)))
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
  Converts a schema to an SDL string

  Per the spec, only types that are actually referenced directly or transitively from
  the root query, subscription, or mutation objects are included.

  ## Example

      Absinthe.Schema.to_sdl(MyAppWeb.Schema)
      "schema {
        query {...}
      }"
  """
  @spec to_sdl(schema :: t) :: String.t()
  def to_sdl(schema) do
    pipeline =
      schema
      |> Absinthe.Pipeline.for_schema(prototype_schema: schema.__absinthe_prototype_schema__)
      |> Absinthe.Pipeline.upto({Absinthe.Phase.Schema.Validation.Result, pass: :final})
      |> apply_modifiers(schema)

    # we can be assertive here, since this same pipeline was already used to
    # successfully compile the schema.
    {:ok, bp, _} = Absinthe.Pipeline.run(schema.__absinthe_blueprint__, pipeline)

    inspect(bp, pretty: true)
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

  def implementors(schema, %Type.Interface{identifier: identifier}) do
    implementors(schema, identifier)
  end

  @doc """
  List all types on a schema
  """
  @spec types(t) :: [Type.t()]
  def types(schema) do
    schema.__absinthe_types__
    |> Map.keys()
    |> Enum.map(&lookup_type(schema, &1))
  end

  @doc """
  Get all introspection types
  """
  @spec introspection_types(t) :: [Type.t()]
  def introspection_types(schema) do
    schema
    |> Schema.types()
    |> Enum.filter(&Type.introspection?/1)
  end
end
