defmodule Absinthe.Schema do
  import Absinthe.Schema.Notation

  @moduledoc """
  Define a GraphQL schema.

  See also `Absinthe.Schema.Notation` for a reference of the macros imported by
  this module available to build types for your schema.

  ## Basic Usage

  To define a schema, `use Absinthe.Schema` within
  a module. This marks your module as adhering to the
  `Absinthe.Schema` behaviour, and sets up some macros
  and utility functions for your use:

  ```
  defmodule App.Schema do
    use Absinthe.Schema

    # ... define it here!

  end
  ```

  Now, define a `query` (and optionally, `mutation`
  and `subscription`).

  We'll define a `query` that has one field, `item`, to support
  querying for an item record by its ID:

  ```
  # Just for the example. You're probably using Ecto or
  # something much more interesting than a module attribute-based
  # database!
  @fake_db %{
    "foo" => %{id: "foo", name: "Foo", value: 4},
    "bar" => %{id: "bar", name: "Bar", value: 5}
  }

  query do
    @desc "Get an item by ID"
    field :item, :item do

      @desc "The ID of the item"
      arg :id, type: non_null(:id)

      resolve fn %{id: id}, _ ->
        {:ok, Map.get(@fake_db, id)}
      end
    end
  end
  ```

  For more information on object types (especially how the `resolve`
  function works above), see `Absinthe.Type.Object`.

  You may also notice we've declared that the resolved value of the field
  to be of `type: :item`. We now need to define exactly what an `:item` is,
  and what fields it contains.

  ```
  @desc "A valuable Item"
  object :item do
    field :id, :id

    @desc "The item's name"
    field :name, :string,

    field :value, :integer, description: "Recently appraised value"
  end
  ```

  We can also load types from other modules using the `import_types`
  macro:

  ```
  defmodule App.Schema do
    use Absinthe.Schema

    import_types App.Schema.Scalars
    import_types App.Schema.Objects

    # ... schema definition

  end
  ```

  Our `:item` type above could then move into `App.Schema.Objects`:

  ```
  defmodule App.Schema.Objects do
    use Absinthe.Schema.Notation

    object :item do
      # ... type definition
    end

    # ... other objects!

  end
  ```
  """

  @typedoc """
  A module defining a schema.
  """
  @type t :: module

  alias Absinthe.Type
  alias Absinthe.Language
  alias __MODULE__

  defmacro __using__(opts \\ []) do
    quote(generated: true) do
      use Absinthe.Schema.Notation, unquote(opts)
      import unquote(__MODULE__), only: :macros

      import_types Absinthe.Type.BuiltIns

      @after_compile unquote(__MODULE__)
      @behaviour unquote(__MODULE__)

      @doc false
      def __absinthe_middleware__(middleware, field, %{identifier: :mutation} = object) do
        # mutation objects should run publication triggers
        middleware
        |> Absinthe.Schema.__ensure_middleware__(field, object)
        |> Absinthe.Subscription.add_middleware()
        |> __do_absinthe_middleware__(field, object)
      end

      def __absinthe_middleware__(middleware, field, object) do
        __do_absinthe_middleware__(middleware, field, object)
      end

      defp __do_absinthe_middleware__(middleware, field, object) do
        # run field against user supplied function
        middleware
        |> Absinthe.Schema.__ensure_middleware__(field, object)
        |> __MODULE__.middleware(field, object)
        |> case do
          [] ->
            raise """
            Middleware callback must return a non empty list of middleware!
            """

          middleware ->
            middleware
        end
      end

      @doc false
      def middleware(middleware, _field, _object) do
        middleware
      end

      @doc false
      def context(context) do
        context
      end

      @doc false
      def __absinthe_lookup__(key) do
        key
        |> __absinthe_type__
        |> case do
          %Absinthe.Type.Object{} = object ->
            fields =
              Map.new(object.fields, fn {identifier, field} ->
                {identifier,
                 %{field | middleware: __absinthe_middleware__(field.middleware, field, object)}}
              end)

            %{object | fields: fields}

          type ->
            type
        end
      end

      @doc false
      def plugins do
        Absinthe.Plugin.defaults()
      end

      defoverridable middleware: 3, plugins: 0, context: 1
    end
  end

  @doc false
  def __ensure_middleware__([], _field, %{identifier: :subscription}) do
    [Absinthe.Middleware.PassParent]
  end

  def __ensure_middleware__([], %{identifier: identifier}, _) do
    [{Absinthe.Middleware.MapGet, identifier}]
  end

  def __ensure_middleware__(middleware, _field, _object) do
    middleware
  end

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

  @doc """
  List of Plugins to run before / after resolution.

  Plugins are modules that implement the `Absinthe.Plugin` behaviour. These modules
  have the opportunity to run callbacks before and after the resolution of the entire
  document, and have access to the resolution accumulator.

  Plugins must be specified by the schema, so that Absinthe can make sure they are
  all given a chance to run prior to resolution.
  """
  @callback plugins() :: [Absinthe.Plugin.t()]
  @callback middleware([Absinthe.Middleware.spec(), ...], Type.Field.t(), Type.Object.t()) :: [
              Absinthe.Middleware.spec(),
              ...
            ]
  @callback context(map) :: map

  @doc false
  def __after_compile__(env, _bytecode) do
    [
      env.module.__absinthe_errors__,
      Schema.Rule.check(env.module)
    ]
    |> List.flatten()
    |> case do
      [] ->
        nil

      details ->
        raise Absinthe.Schema.Error, details
    end
  end

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
      |> Keyword.put(:identifier, :query)

    Absinthe.Schema.Notation.scope(env, :object, :query, attrs, block)
    Absinthe.Schema.Notation.desc_attribute_recorder(:query)
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
      |> Keyword.put(:identifier, :mutation)

    Absinthe.Schema.Notation.scope(env, :object, :mutation, attrs, block)
    Absinthe.Schema.Notation.desc_attribute_recorder(:query)
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
      |> Keyword.put(:identifier, :subscription)

    Absinthe.Schema.Notation.scope(env, :object, :subscription, attrs, block)
    Absinthe.Schema.Notation.desc_attribute_recorder(:query)
  end

  # Lookup a directive that in used by/available to a schema
  @doc """
  Lookup a directive.
  """
  @spec lookup_directive(t, atom | binary) :: Type.Directive.t() | nil
  def lookup_directive(schema, name) do
    schema.__absinthe_directive__(name)
  end

  @doc """
  Lookup a type by name, identifier, or by unwrapping.
  """
  @spec lookup_type(atom, Type.wrapping_t() | Type.t() | Type.identifier_t(), Keyword.t()) ::
          Type.t() | nil
  def lookup_type(schema, type, options \\ [unwrap: true]) do
    cond do
      is_atom(type) ->
        cached_lookup_type(schema, type)

      is_binary(type) ->
        cached_lookup_type(schema, type)

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

  @doc false
  def cached_lookup_type(schema, type) do
    # Originally, schema types were entirely literals, and very fast to lookup.
    # Fast lookup types are assumed throughout the codebase, as it is often mandatory
    # to lookup a type in several different places.
    #
    # Now, type/field imports, middleware logic, and other things means they aren't
    # literals anymore, and aren't as fast as they should be. Thus the use of the pdict
    # to make sure we only pay this cost once.
    #
    # Ideal solution: mandate that types are macro-escapable, and then we can turn
    # them back into literals. The main issue there is resolution functions.

    case :erlang.get({schema, type}) do
      :undefined ->
        result = schema.__absinthe_lookup__(type)
        :erlang.put({schema, type}, result)
        result

      result ->
        result
    end
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
