defmodule Absinthe.Schema do
  alias Absinthe.Type
  alias __MODULE__

  @type t :: module

  defmacro __using__(_opt) do
    Module.register_attribute(__CALLER__.module, :pipeline_modifier,
      accumulate: true,
      persist: true
    )

    quote do
      use Absinthe.Schema.Notation
      import unquote(__MODULE__), only: :macros

      @after_compile unquote(__MODULE__)

      defdelegate __absinthe_type__(name), to: __MODULE__.Compiled
      defdelegate __absinthe_directive__(name), to: __MODULE__.Compiled
      defdelegate __absinthe_types__(), to: __MODULE__.Compiled
      defdelegate __absinthe_directives__(), to: __MODULE__.Compiled
      defdelegate __absinthe_interface_implementors__(), to: __MODULE__.Compiled

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

      @doc false
      def decorations(node, ancestors) do
        []
      end

      defoverridable(context: 1, middleware: 3, plugins: 0, decorations: 2)
    end
  end

  @object_type Absinthe.Blueprint.Schema.ObjectTypeDefinition

  @default_query_name "RootQueryType"
  @doc """
  Defines a root Query object
  """
  defmacro query(raw_attrs \\ [name: @default_query_name], do: block) do
    record_query(__CALLER__, raw_attrs, block)
  end

  defp record_query(env, raw_attrs, block) do
    attrs =
      raw_attrs
      |> Keyword.put_new(:name, @default_query_name)

    Absinthe.Schema.Notation.record!(env, @object_type, :query, attrs, block)
  end

  @default_mutation_name "RootMutationType"
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
  defmacro mutation(raw_attrs \\ [name: @default_mutation_name], do: block) do
    record_mutation(__CALLER__, raw_attrs, block)
  end

  defp record_mutation(env, raw_attrs, block) do
    attrs =
      raw_attrs
      |> Keyword.put_new(:name, @default_mutation_name)

    Absinthe.Schema.Notation.record!(env, @object_type, :mutation, attrs, block)
  end

  @default_subscription_name "RootSubscriptionType"
  @doc """
  Defines a root Subscription object

  Subscriptions in GraphQL let a client submit a document to the server that
  outlines what data they want to receive in the event of particular updates.

  For a full walk through of how to setup your project with subscriptions and
  Phoenix see the Absinthe.Phoenix project moduledoc.

  When you push a mutation, you can have selections on that mutation result
  to get back data you need, IE

  ```
  mutation {
    createUser(accountId: 1, name: "bob") {
      id
      account { name }
    }
  }
  ```

  However, what if you want to know when OTHER people create a new user, so that
  your UI can update as well. This is the point of subscriptions.

  ```
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

      config fn args,_info ->
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
  defmacro subscription(raw_attrs \\ [name: @default_subscription_name], do: block) do
    record_subscription(__CALLER__, raw_attrs, block)
  end

  defp record_subscription(env, raw_attrs, block) do
    attrs =
      raw_attrs
      |> Keyword.put_new(:name, @default_subscription_name)

    Absinthe.Schema.Notation.record!(env, @object_type, :subscription, attrs, block)
  end

  def __after_compile__(env, _) do
    pipeline = Absinthe.Pipeline.for_schema(env.module)

    pipeline =
      env.module
      |> Module.get_attribute(:pipeline_modifier)
      |> Enum.reduce(pipeline, fn
        {module, function}, pipeline ->
          apply(module, function, [pipeline])

        module, pipeline ->
          module.pipeline(pipeline)
      end)

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
