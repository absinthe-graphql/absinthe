defmodule Absinthe.Schema.Notation do
  alias Absinthe.Blueprint.Schema
  alias Absinthe.Utils

  @moduledoc """
  Provides a set of macros to use when creating a schema. Especially useful
  when moving definitions out into a different module than the schema itself.

  ## Example

      defmodule MyAppWeb.Schema.Types do
        use Absinthe.Schema.Notation

        object :item do
          field :id, :id
          field :name, :string
        end

        # ...

      end

  """

  Module.register_attribute(__MODULE__, :placement, accumulate: true)

  defmacro __using__(import_opts \\ [only: :macros]) do
    Module.register_attribute(__CALLER__.module, :absinthe_blueprint, accumulate: true)
    Module.register_attribute(__CALLER__.module, :absinthe_desc, accumulate: true)
    put_attr(__CALLER__.module, %Absinthe.Blueprint{schema: __CALLER__.module})
    Module.put_attribute(__CALLER__.module, :absinthe_scope_stack, [:schema])
    Module.put_attribute(__CALLER__.module, :absinthe_scope_stack_stash, [])

    quote do
      import Absinthe.Resolution.Helpers,
        only: [
          async: 1,
          async: 2,
          batch: 3,
          batch: 4
        ]

      Module.register_attribute(__MODULE__, :__absinthe_type_import__, accumulate: true)
      @desc nil
      import unquote(__MODULE__), unquote(import_opts)
      @before_compile unquote(__MODULE__)
    end
  end

  ### Macro API ###

  @placement {:config, [under: [:field]]}
  @doc """
  Configure a subscription field.

  The first argument to the config function is the field arguments passed in the subscription.
  The second argument is an `Absinthe.Resolution` struct, which includes information
  like the context and other execution data.

  ## Placement

  #{Utils.placement_docs(@placement)}

  ## Examples

  ```elixir
  config fn args, %{context: context} ->
    if authorized?(context) do
      {:ok, topic: args.client_id}
    else
      {:error, "unauthorized"}
    end
  end
  ```

  Alternatively can provide a list of topics:

  ```elixir
  config fn _, _ ->
    {:ok, topic: ["topic_one", "topic_two", "topic_three"]}
  end
  ```

  Using `context_id` option to allow de-duplication of updates:

  ```elixir
  config fn _, %{context: context} ->
    if authorized?(context) do
      {:ok, topic: "topic_one", context_id: "authorized"}
    else
      {:ok, topic: "topic_one", context_id: "not-authorized"}
    end
  end
  ```

  See `Absinthe.Schema.subscription/1` for details
  """
  defmacro config(config_fun) do
    __CALLER__
    |> recordable!(:config, @placement[:config])
    |> record_config!(config_fun)
  end

  @placement {:trigger, [under: [:field]]}
  @doc """
  Sets triggers for a subscription, and configures which topics to publish to when that subscription
  is triggered.

  A trigger is the name of a mutation. When that mutation runs, data is pushed to the clients
  who are subscribed to the subscription.

  A subscription can have many triggers, and a trigger can push to many topics.

  ## Placement

  #{Utils.placement_docs(@placement)}

  ## Example

  ```elixir
  mutation do
    field :gps_event, :gps_event
    field :user_checkin, :user
  end

  subscription do
    field :location_update, :user do
      arg :user_id, non_null(:id)

      config fn args, _ ->
        {:ok, topic: args.user_id}
      end

      trigger :gps_event, topic: fn gps_event ->
        gps_event.user_id
      end

      # Trigger on a list of mutations
      trigger [:user_checkin], topic: fn user ->
        # Returning a list of topics triggers the subscription for each of the topics in the list.
        [user.id, user.friend.id]
      end
    end
  end
  ```

  Trigger functions are only called once per event, so database calls within
  them do not present a significant burden.

  See the `Absinthe.Schema.subscription/2` macro docs for additional details
  """
  defmacro trigger(mutations, attrs) do
    __CALLER__
    |> recordable!(:trigger, @placement[:trigger])
    |> record_trigger!(List.wrap(mutations), attrs)
  end

  # OBJECT

  @placement {:object, [toplevel: true]}
  @doc """
  Define an object type.

  Adds an `Absinthe.Type.Object` to your schema.

  ## Placement

  #{Utils.placement_docs(@placement)}

  ## Examples

  Basic definition:

  ```
  object :car do
    # ...
  end
  ```

  Providing a custom name:

  ```
  object :car, name: "CarType" do
    # ...
  end
  ```
  """
  @reserved_identifiers ~w(query mutation subscription)a
  defmacro object(identifier, attrs \\ [], block)

  defmacro object(identifier, _attrs, _block) when identifier in @reserved_identifiers do
    raise Absinthe.Schema.Notation.Error,
          "Invalid schema notation: cannot create an `object` " <>
            "with reserved identifier `#{identifier}`"
  end

  defmacro object(identifier, attrs, do: block) do
    block =
      for {identifier, args} <- build_directives(attrs) do
        quote do
          directive(unquote(identifier), unquote(args))
        end
      end ++ block

    {attrs, block} =
      case Keyword.pop(attrs, :meta) do
        {nil, attrs} ->
          {attrs, block}

        {meta, attrs} ->
          meta_ast =
            quote do
              meta unquote(meta)
            end

          block = [meta_ast, block]
          {attrs, block}
      end

    __CALLER__
    |> recordable!(:object, @placement[:object])
    |> record!(
      Schema.ObjectTypeDefinition,
      identifier,
      attrs |> Keyword.update(:description, nil, &wrap_in_unquote/1),
      block
    )
  end

  @placement {:interfaces, [under: [:object, :interface]]}
  @doc """
  Declare implemented interfaces for an object.

  See also `interface/1`, which can be used for one interface,
  and `interface/3`, used to define interfaces themselves.

  ## Placement

  #{Utils.placement_docs(@placement)}

  ## Examples

  ```
  object :car do
    interfaces [:vehicle, :branded]
    # ...
  end
  ```
  """
  defmacro interfaces(ifaces) when is_list(ifaces) do
    __CALLER__
    |> recordable!(:interfaces, @placement[:interfaces])
    |> record_interfaces!(ifaces)
  end

  @placement {:deprecate, [under: [:field]]}
  @doc """
  Mark a field as deprecated

  In most cases you can simply pass the deprecate: "message" attribute. However
  when using the block form of a field it can be nice to also use this macro.

  ## Placement

  #{Utils.placement_docs(@placement)}

  ## Examples
  ```
  field :foo, :string do
    deprecate "Foo will no longer be supported"
  end
  ```

  This is how to deprecate other things
  ```
  field :foo, :string do
    arg :bar, :integer, deprecate: "This isn't supported either"
  end

  enum :colors do
    value :red
    value :blue, deprecate: "This isn't supported"
  end
  ```
  """
  defmacro deprecate(msg) do
    __CALLER__
    |> recordable!(:deprecate, @placement[:deprecate])
    |> record_deprecate!(msg)
  end

  @doc """
  Declare an implemented interface for an object.

  Adds an `Absinthe.Type.Interface` to your schema.

  See also `interfaces/1`, which can be used for multiple interfaces,
  and `interface/3`, used to define interfaces themselves.

  ## Examples

  ```
  object :car do
    interface :vehicle
    # ...
  end
  ```
  """
  @placement {:interface_attribute, [under: [:object, :interface]]}
  defmacro interface(identifier) do
    __CALLER__
    |> recordable!(:interface_attribute, @placement[:interface_attribute])
    |> record_interface!(identifier)
  end

  # INTERFACES

  @placement {:interface, [toplevel: true]}
  @doc """
  Define an interface type.

  Adds an `Absinthe.Type.Interface` to your schema.

  Also see `interface/1` and `interfaces/1`, which declare
  that an object implements one or more interfaces.

  ## Placement

  #{Utils.placement_docs(@placement)}

  ## Examples

  ```
  interface :vehicle do
    field :wheel_count, :integer
  end

  object :rally_car do
    field :wheel_count, :integer
    interface :vehicle
  end
  ```
  """
  defmacro interface(identifier, attrs \\ [], do: block) do
    __CALLER__
    |> recordable!(:interface, @placement[:interface])
    |> record!(Schema.InterfaceTypeDefinition, identifier, attrs, block)
  end

  @placement {:resolve_type, [under: [:interface, :union]]}
  @doc """
  Define a type resolver for a union or interface.

  See also:
  * `Absinthe.Type.Interface`
  * `Absinthe.Type.Union`

  ## Placement

  #{Utils.placement_docs(@placement)}

  ## Examples

  ```
  interface :entity do
    # ...
    resolve_type fn
      %{employee_count: _},  _ ->
        :business
      %{age: _}, _ ->
        :person
    end
  end
  ```
  """
  defmacro resolve_type(func_ast) do
    __CALLER__
    |> recordable!(:resolve_type, @placement[:resolve_type])
    |> record_resolve_type!(func_ast)
  end

  defp handle_field_attrs(attrs, caller) do
    block =
      for {identifier, arg_attrs} <- Keyword.get(attrs, :args, []) do
        quote do
          arg unquote(identifier), unquote(arg_attrs)
        end
      end

    block =
      for {identifier, args} <- build_directives(attrs) do
        quote do
          directive(unquote(identifier), unquote(args))
        end
      end ++ block

    block =
      case Keyword.get(attrs, :meta) do
        nil ->
          block

        meta ->
          meta_ast =
            quote do
              meta unquote(meta)
            end

          [meta_ast, block]
      end

    {func_ast, attrs} = Keyword.pop(attrs, :resolve)

    block =
      if func_ast do
        [
          quote do
            resolve unquote(func_ast)
          end
        ]
      else
        []
      end ++ block

    attrs =
      attrs
      |> expand_ast(caller)
      |> Keyword.delete(:deprecate)
      |> Keyword.delete(:directives)
      |> Keyword.delete(:args)
      |> Keyword.delete(:meta)
      |> Keyword.update(:description, nil, &wrap_in_unquote/1)
      |> Keyword.update(:default_value, nil, &wrap_in_unquote/1)

    {attrs, block}
  end

  # FIELDS
  @placement {:field, [under: [:input_object, :interface, :object]]}
  @doc """
  Defines a GraphQL field

  See `field/4`
  """

  defmacro field(identifier, attrs) when is_list(attrs) do
    {attrs, block} = handle_field_attrs(attrs, __CALLER__)

    __CALLER__
    |> recordable!(:field, @placement[:field])
    |> record!(Schema.FieldDefinition, identifier, attrs, block)
  end

  defmacro field(identifier, type) do
    {attrs, block} = handle_field_attrs([type: type], __CALLER__)

    __CALLER__
    |> recordable!(:field, @placement[:field])
    |> record!(Schema.FieldDefinition, identifier, attrs, block)
  end

  @doc """
  Defines a GraphQL field

  See `field/4`
  """
  defmacro field(identifier, attrs, do: block) when is_list(attrs) do
    {attrs, more_block} = handle_field_attrs(attrs, __CALLER__)
    block = more_block ++ List.wrap(block)

    __CALLER__
    |> recordable!(:field, @placement[:field])
    |> record!(Schema.FieldDefinition, identifier, attrs, block)
  end

  defmacro field(identifier, type, do: block) do
    {attrs, _} = handle_field_attrs([type: type], __CALLER__)

    __CALLER__
    |> recordable!(:field, @placement[:field])
    |> record!(Schema.FieldDefinition, identifier, attrs, block)
  end

  defmacro field(identifier, type, attrs) do
    {attrs, block} = handle_field_attrs(Keyword.put(attrs, :type, type), __CALLER__)

    __CALLER__
    |> recordable!(:field, @placement[:field])
    |> record!(Schema.FieldDefinition, identifier, attrs, block)
  end

  @doc """
  Defines a GraphQL field.

  ## Placement

  #{Utils.placement_docs(@placement)}

  `query`, `mutation`, and `subscription` are
  all objects under the covers, and thus you'll find `field` definitions under
  those as well.

  ## Examples
  ```
  field :id, :id
  field :age, :integer, description: "How old the item is"
  field :name, :string do
    description "The name of the item"
  end
  field :location, type: :location
  ```
  """
  defmacro field(identifier, type, attrs, do: block) do
    attrs = Keyword.put(attrs, :type, type)
    {attrs, more_block} = handle_field_attrs(attrs, __CALLER__)
    block = more_block ++ List.wrap(block)

    __CALLER__
    |> recordable!(:field, @placement[:field])
    |> record!(Schema.FieldDefinition, identifier, attrs, block)
  end

  @placement {:resolve, [under: [:field]]}
  @doc """
  Defines a resolve function for a field

  Specify a 2 or 3 arity function to call when resolving a field.

  You can either hard code a particular anonymous function, or have a function
  call that returns a 2 or 3 arity anonymous function. See examples for more information.

  Note that when using a hard coded anonymous function, the function will not
  capture local variables.

  ### 3 Arity Functions

  The first argument to the function is the parent entity.
  ```
  {
    user(id: 1) {
      name
    }
  }
  ```
  A resolution function on the `name` field would have the result of the `user(id: 1)` field
  as its first argument. Top level fields have the `root_value` as their first argument.
  Unless otherwise specified, this defaults to an empty map.

  The second argument to the resolution function is the field arguments. The final
  argument is an `Absinthe.Resolution` struct, which includes information like
  the `context` and other execution data.

  ### 2 Arity Function

  Exactly the same as the 3 arity version, but without the first argument (the parent entity)

  ## Placement

  #{Utils.placement_docs(@placement)}

  ## Examples
  ```
  query do
    field :person, :person do
      resolve &Person.resolve/2
    end
  end
  ```

  ```
  query do
    field :person, :person do
      resolve fn %{id: id}, _ ->
        {:ok, Person.find(id)}
      end
    end
  end
  ```

  ```
  query do
    field :person, :person do
      resolve lookup(:person)
    end
  end

  def lookup(:person) do
    fn %{id: id}, _ ->
      {:ok, Person.find(id)}
    end
  end
  ```
  """
  defmacro resolve(func_ast) do
    __CALLER__
    |> recordable!(:resolve, @placement[:resolve])

    quote do
      middleware Absinthe.Resolution, unquote(func_ast)
    end
  end

  @placement {:complexity, [under: [:field]]}
  @doc """
  Set the complexity of a field

  For a field, the first argument to the function you supply to `complexity/1` is the user arguments -- just as a field's resolver can use user arguments to resolve its value, the complexity function that you provide can use the same arguments to calculate the field's complexity.

  The second argument passed to your complexity function is the sum of all the complexity scores of all the fields nested below the current field.

  An optional third argument is passed an `Absinthe.Complexity` struct, which includes information
  like the context passed to `Absinthe.run/3`.

  ## Placement

  #{Utils.placement_docs(@placement)}

  ## Examples
  ```
  query do
    field :people, list_of(:person) do
      arg :limit, :integer, default_value: 10
      complexity fn %{limit: limit}, child_complexity ->
        # set complexity based on maximum number of items in the list and
        # complexity of a child.
        limit * child_complexity
      end
    end
  end
  ```
  """
  defmacro complexity(func_ast) do
    __CALLER__
    |> recordable!(:complexity, @placement[:complexity])
    |> record_complexity!(func_ast)
  end

  @placement {:middleware, [under: [:field]]}
  defmacro middleware(new_middleware, opts \\ []) do
    __CALLER__
    |> recordable!(:middleware, @placement[:middleware])
    |> record_middleware!(new_middleware, opts)
  end

  @placement {:is_type_of, [under: [:object]]}
  @doc """

  ## Placement

  #{Utils.placement_docs(@placement)}
  """
  defmacro is_type_of(func_ast) do
    __CALLER__
    |> recordable!(:is_type_of, @placement[:is_type_of])
    |> record_is_type_of!(func_ast)
  end

  @placement {:arg, [under: [:directive, :field]]}
  # ARGS
  @doc """
  Add an argument.

  ## Placement

  #{Utils.placement_docs(@placement)}

  ## Examples

  ```
  field do
    arg :size, :integer
    arg :name, non_null(:string), description: "The desired name"
    arg :public, :boolean, default_value: true
  end
  ```
  """
  defmacro arg(identifier, type, attrs) do
    {attrs, block} = handle_arg_attrs(identifier, type, attrs)

    __CALLER__
    |> recordable!(:arg, @placement[:arg])
    |> record!(Schema.InputValueDefinition, identifier, attrs, block)
  end

  @doc """
  Add an argument.

  See `arg/3`
  """
  defmacro arg(identifier, attrs) when is_list(attrs) do
    {attrs, block} = handle_arg_attrs(identifier, nil, attrs)

    __CALLER__
    |> recordable!(:arg, @placement[:arg])
    |> record!(Schema.InputValueDefinition, identifier, attrs, block)
  end

  defmacro arg(identifier, type) do
    {attrs, block} = handle_arg_attrs(identifier, type, [])

    __CALLER__
    |> recordable!(:arg, @placement[:arg])
    |> record!(Schema.InputValueDefinition, identifier, attrs, block)
  end

  # SCALARS

  @placement {:scalar, [toplevel: true]}
  @doc """
  Define a scalar type

  A scalar type requires `parse/1` and `serialize/1` functions.

  ## Placement

  #{Utils.placement_docs(@placement)}

  ## Examples
  ```
  scalar :time, description: "ISOz time" do
    parse &Timex.parse(&1.value, "{ISOz}")
    serialize &Timex.format!(&1, "{ISOz}")
  end
  ```
  """
  defmacro scalar(identifier, attrs, do: block) do
    __CALLER__
    |> recordable!(:scalar, @placement[:scalar])
    |> record_scalar!(identifier, attrs, block)
  end

  @doc """
  Defines a scalar type

  See `scalar/3`
  """
  defmacro scalar(identifier, do: block) do
    __CALLER__
    |> recordable!(:scalar, @placement[:scalar])
    |> record_scalar!(identifier, [], block)
  end

  defmacro scalar(identifier, attrs) do
    __CALLER__
    |> recordable!(:scalar, @placement[:scalar])
    |> record_scalar!(identifier, attrs, nil)
  end

  @placement {:serialize, [under: [:scalar]]}
  @doc """
  Defines a serialization function for a `scalar` type

  The specified `serialize` function is used on outgoing data. It should simply
  return the desired external representation.

  ## Placement

  #{Utils.placement_docs(@placement)}
  """
  defmacro serialize(func_ast) do
    __CALLER__
    |> recordable!(:serialize, @placement[:serialize])
    |> record_serialize!(func_ast)
  end

  @placement {:private,
              [under: [:field, :object, :input_object, :enum, :scalar, :interface, :union]]}
  @doc false
  defmacro private(owner, key, value) do
    __CALLER__
    |> recordable!(:private, @placement[:private])
    |> record_private!(owner, [{key, value}])
  end

  @placement {:meta,
              [under: [:field, :object, :input_object, :enum, :scalar, :interface, :union]]}
  @doc """
  Defines a metadata key/value pair for a custom type.

  For more info see `meta/1`

  ### Examples

  ```
  meta :cache, false
  ```

  ## Placement

  #{Utils.placement_docs(@placement)}
  """
  defmacro meta(key, value) do
    __CALLER__
    |> recordable!(:meta, @placement[:meta])
    |> record_private!(:meta, [{key, value}])
  end

  @doc """
  Defines list of metadata's key/value pair for a custom type.

  This is generally used to facilitate libraries that want to augment Absinthe
  functionality

  ## Examples

  ```
  object :user do
    meta cache: true, ttl: 22_000
  end

  object :user, meta: [cache: true, ttl: 22_000] do
    # ...
  end
  ```

  The meta can be accessed via the `Absinthe.Type.meta/2` function.

  ```
  user_type = Absinthe.Schema.lookup_type(MyApp.Schema, :user)

  Absinthe.Type.meta(user_type, :cache)
  #=> true

  Absinthe.Type.meta(user_type)
  #=> [cache: true, ttl: 22_000]
  ```

  ## Placement

  #{Utils.placement_docs(@placement)}
  """
  defmacro meta(keyword_list) do
    __CALLER__
    |> recordable!(:meta, @placement[:meta])
    |> record_private!(:meta, keyword_list)
  end

  @placement {:parse, [under: [:scalar]]}
  @doc """
  Defines a parse function for a `scalar` type

  The specified `parse` function is used on incoming data to transform it into
  an elixir datastructure.

  It should return `{:ok, value}` or `:error`

  ## Placement

  #{Utils.placement_docs(@placement)}
  """
  defmacro parse(func_ast) do
    __CALLER__
    |> recordable!(:parse, @placement[:parse])
    |> record_parse!(func_ast)
  end

  # DIRECTIVES

  @placement {:directive, [toplevel: true]}
  @placement {:applied_directive,
              [
                under: [
                  :arg,
                  :enum,
                  :field,
                  :input_object,
                  :interface,
                  :object,
                  :scalar,
                  :union,
                  :value
                ]
              ]}

  @doc """
  Defines or applies a directive

  ## Defining a directive
  ### Placement

  #{Utils.placement_docs(@placement, :directive)}

  ### Examples

  ```elixir
  directive :mydirective do
    arg :if, non_null(:boolean), description: "Skipped when true."
    on [:field, :fragment_spread, :inline_fragment]

    expand fn
      %{if: true}, node ->
        Blueprint.put_flag(node, :skip, __MODULE__)
      _, node ->
        node
    end
  end
  ```

  ## Applying a type system directive
  Directives can be applied in your schema. E.g. by default the `@deprecated`
  directive is available to be applied to fields and enum values.

  You can define your own type system directives. See `Absinthe.Schema.Prototype`
  for more information.

  ### Placement

  #{Utils.placement_docs(@placement, :applied_directive)}

  ### Examples

  When you have a type system directive named `:feature` it can be applied as
  follows:

  ```elixir
  object :post do
    directive :feature, name: ":object"

    field :name, :string do
      deprecate "Bye"
    end
  end

  scalar :sweet_scalar do
    directive :feature, name: ":scalar"
    parse &Function.identity/1
    serialize &Function.identity/1
  end
  ```
  """
  defmacro directive(identifier, attrs, do: block) when is_list(attrs) when not is_nil(block) do
    __CALLER__
    |> recordable!(:directive, @placement[:directive])
    |> record_directive!(identifier, attrs, block)
  end

  defmacro directive(identifier, do: block) when not is_nil(block) do
    __CALLER__
    |> recordable!(:directive, @placement[:directive])
    |> record_directive!(identifier, [], block)
  end

  defmacro directive(identifier, attrs) when is_list(attrs) do
    __CALLER__
    |> recordable!(:directive, @placement[:applied_directive])
    |> record_applied_directive!(identifier, attrs)
  end

  defmacro directive(identifier) do
    __CALLER__
    |> recordable!(:directive, @placement[:applied_directive])
    |> record_applied_directive!(identifier, [])
  end

  @placement {:on, [under: [:directive]]}
  @doc """
  Declare a directive as operating an a AST node type

  See `directive/2`

  ## Placement

  #{Utils.placement_docs(@placement)}
  """
  defmacro on(ast_node) do
    __CALLER__
    |> recordable!(:on, @placement[:on])
    |> record_locations!(ast_node)
  end

  @placement {:expand, [under: [:directive]]}
  @doc """
  Define the expansion for a directive

  ## Placement

  #{Utils.placement_docs(@placement)}
  """
  defmacro expand(func_ast) do
    __CALLER__
    |> recordable!(:expand, @placement[:expand])
    |> record_expand!(func_ast)
  end

  @placement {:repeatable, [under: [:directive]]}
  @doc """
  Set whether the directive can be applied multiple times
  an entity.

  If omitted, defaults to `false`

  ## Placement

  #{Utils.placement_docs(@placement)}
  """
  defmacro repeatable(bool) do
    __CALLER__
    |> recordable!(:repeatable, @placement[:repeatable])
    |> record_repeatable!(bool)
  end

  # INPUT OBJECTS

  @placement {:input_object, [toplevel: true]}
  @doc """
  Defines an input object

  See `Absinthe.Type.InputObject`

  ## Placement

  #{Utils.placement_docs(@placement)}

  ## Examples
  ```
  input_object :contact_input do
    field :email, non_null(:string)
  end
  ```
  """
  defmacro input_object(identifier, attrs \\ [], do: block) do
    __CALLER__
    |> recordable!(:input_object, @placement[:input_object])
    |> record!(
      Schema.InputObjectTypeDefinition,
      identifier,
      attrs |> Keyword.update(:description, nil, &wrap_in_unquote/1),
      block
    )
  end

  # UNIONS

  @placement {:union, [toplevel: true]}
  @doc """
  Defines a union type

  See `Absinthe.Type.Union`

  ## Placement

  #{Utils.placement_docs(@placement)}

  ## Examples
  ```
  union :search_result do
    description "A search result"

    types [:person, :business]
    resolve_type fn
      %Person{}, _ -> :person
      %Business{}, _ -> :business
    end
  end
  ```
  """
  defmacro union(identifier, attrs \\ [], do: block) do
    __CALLER__
    |> recordable!(:union, @placement[:union])
    |> record!(
      Schema.UnionTypeDefinition,
      identifier,
      attrs |> Keyword.update(:description, nil, &wrap_in_unquote/1),
      block
    )
  end

  @placement {:types, [under: [:union]]}
  @doc """
  Defines the types possible under a union type

  See `union/3`

  ## Placement

  #{Utils.placement_docs(@placement)}
  """
  defmacro types(types) do
    __CALLER__
    |> recordable!(:types, @placement[:types])
    |> record_types!(types)
  end

  # ENUMS

  @placement {:enum, [toplevel: true]}
  @doc """
  Defines an enum type

  ## Placement

  #{Utils.placement_docs(@placement)}

  ## Examples

  Handling `RED`, `GREEN`, `BLUE` values from the query document:

  ```
  enum :color do
    value :red
    value :green
    value :blue
  end
  ```

  A given query document might look like:

  ```graphql
  {
    foo(color: RED)
  }
  ```

  Internally you would get an argument in elixir that looks like:

  ```elixir
  %{color: :red}
  ```

  If your return value is an enum, it will get serialized out as:

  ```json
  {"color": "RED"}
  ```

  You can provide custom value mappings. Here we use `r`, `g`, `b` values:

  ```
  enum :color do
    value :red, as: "r"
    value :green, as: "g"
    value :blue, as: "b"
  end
  ```

  """
  defmacro enum(identifier, attrs, do: block) do
    attrs = handle_enum_attrs(attrs, __CALLER__)

    __CALLER__
    |> recordable!(:enum, @placement[:enum])
    |> record!(Schema.EnumTypeDefinition, identifier, attrs, block)
  end

  @doc """
  Defines an enum type

  See `enum/3`
  """
  defmacro enum(identifier, do: block) do
    __CALLER__
    |> recordable!(:enum, @placement[:enum])
    |> record!(Schema.EnumTypeDefinition, identifier, [], block)
  end

  defmacro enum(identifier, attrs) do
    attrs = handle_enum_attrs(attrs, __CALLER__)

    __CALLER__
    |> recordable!(:enum, @placement[:enum])
    |> record!(Schema.EnumTypeDefinition, identifier, attrs, [])
  end

  defp handle_enum_attrs(attrs, env) do
    attrs
    |> expand_ast(env)
    |> Keyword.update(:values, [], &[wrap_in_unquote(&1)])
    |> Keyword.update(:description, nil, &wrap_in_unquote/1)
  end

  @placement {:value, [under: [:enum]]}
  @doc """
  Defines a value possible under an enum type

  See `enum/3`

  ## Placement

  #{Utils.placement_docs(@placement)}
  """
  defmacro value(identifier, raw_attrs \\ []) do
    attrs = expand_ast(raw_attrs, __CALLER__)

    __CALLER__
    |> recordable!(:value, @placement[:value])
    |> record_value!(identifier, attrs)
  end

  # GENERAL ATTRIBUTES

  @placement {:description, [toplevel: false]}
  @doc """
  Defines a description

  This macro adds a description to any other macro which takes a block.

  Note that you can also specify a description by using `@desc` above any item
  that can take a description attribute.

  ## Placement

  #{Utils.placement_docs(@placement)}
  """
  defmacro description(text) do
    __CALLER__
    |> recordable!(:description, @placement[:description])
    |> record_description!(text)
  end

  # TYPE UTILITIES
  @doc """
  Marks a type reference as non null

  See `field/3` for examples
  """

  defmacro non_null({:non_null, _, _}) do
    raise Absinthe.Schema.Notation.Error,
          "Invalid schema notation: `non_null` must not be nested"
  end

  defmacro non_null(type) do
    %Absinthe.Blueprint.TypeReference.NonNull{of_type: expand_ast(type, __CALLER__)}
  end

  @doc """
  Marks a type reference as a list of the given type

  See `field/3` for examples
  """
  defmacro list_of(type) do
    %Absinthe.Blueprint.TypeReference.List{of_type: expand_ast(type, __CALLER__)}
  end

  @placement {:import_fields, [under: [:input_object, :interface, :object]]}
  @doc """
  Import fields from another object

  ## Example
  ```
  object :news_queries do
    field :all_links, list_of(:link)
    field :main_story, :link
  end

  object :admin_queries do
    field :users, list_of(:user)
    field :pending_posts, list_of(:post)
  end

  query do
    import_fields :news_queries
    import_fields :admin_queries
  end
  ```

  Import fields can also be used on objects created inside other modules that you
  have used import_types on.

  ```
  defmodule MyApp.Schema.NewsTypes do
    use Absinthe.Schema.Notation

    object :news_queries do
      field :all_links, list_of(:link)
      field :main_story, :link
    end
  end
  defmodule MyApp.Schema.Schema do
    use Absinthe.Schema

    import_types MyApp.Schema.NewsTypes

    query do
      import_fields :news_queries
      # ...
    end
  end
  ```
  """
  defmacro import_fields(source_criteria, opts \\ []) do
    source_criteria = expand_ast(source_criteria, __CALLER__)

    put_attr(__CALLER__.module, {:import_fields, {source_criteria, opts}})
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
  defmacro import_types(type_module_ast, opts \\ []) do
    env = __CALLER__

    type_module_ast
    |> Macro.expand(env)
    |> do_import_types(env, opts)
  end

  @placement {:import_sdl, [toplevel: true]}
  @type import_sdl_option :: {:path, String.t() | Macro.t()}
  @doc """
  Import types defined using the Schema Definition Language (SDL).

  TODO: Explain handlers

  ## Placement

  #{Utils.placement_docs(@placement)}

  ## Examples

  Directly embedded SDL:

  ```
  import_sdl \"""
  type Query {
    posts: [Post]
  }

  type Post {
    title: String!
    body: String!
  }
  \"""
  ```

  Loaded from a file location (supporting recompilation on change):

  ```
  import_sdl path: "/path/to/sdl.graphql"
  ```

  TODO: Example for dynamic loading during init
  """
  @spec import_sdl([import_sdl_option(), ...]) :: Macro.t()
  defmacro import_sdl(opts) when is_list(opts) do
    __CALLER__
    |> do_import_sdl(nil, opts)
  end

  @spec import_sdl(String.t() | Macro.t(), [import_sdl_option()]) :: Macro.t()
  defmacro import_sdl(sdl, opts \\ []) do
    __CALLER__
    |> do_import_sdl(sdl, opts)
  end

  defmacro values(values) do
    __CALLER__
    |> record_values!(values)
  end

  ### Recorders ###
  #################

  @scoped_types [
    Schema.ObjectTypeDefinition,
    Schema.FieldDefinition,
    Schema.ScalarTypeDefinition,
    Schema.EnumTypeDefinition,
    Schema.EnumValueDefinition,
    Schema.InputObjectTypeDefinition,
    Schema.InputValueDefinition,
    Schema.UnionTypeDefinition,
    Schema.InterfaceTypeDefinition,
    Schema.DirectiveDefinition
  ]

  def record!(env, type, identifier, attrs, block) when type in @scoped_types do
    attrs = expand_ast(attrs, env)
    scoped_def(env, type, identifier, attrs, block)
  end

  defp build_directives(attrs) do
    if attrs[:deprecate] do
      directive = {:deprecated, reason(attrs[:deprecate])}

      directives = Keyword.get(attrs, :directives, [])
      [directive | directives]
    else
      Keyword.get(attrs, :directives, [])
    end
  end

  defp reason(true), do: []
  defp reason(msg) when is_binary(msg), do: [reason: msg]
  defp reason(msg), do: raise(ArgumentError, "Invalid reason: #{msg}")

  def handle_arg_attrs(identifier, type, raw_attrs) do
    block =
      for {identifier, args} <- build_directives(raw_attrs) do
        quote do
          directive(unquote(identifier), unquote(args))
        end
      end

    attrs =
      raw_attrs
      |> Keyword.put_new(:name, to_string(identifier))
      |> Keyword.put_new(:type, type)
      |> Keyword.delete(:directives)
      |> Keyword.delete(:deprecate)
      |> Keyword.update(:description, nil, &wrap_in_unquote/1)
      |> Keyword.update(:default_value, nil, &wrap_in_unquote/1)

    {attrs, block}
  end

  @doc false
  # Record a directive expand function in the current scope
  def record_expand!(env, func_ast) do
    put_attr(env.module, {:expand, func_ast})
  end

  @doc false
  def record_repeatable!(env, bool) do
    put_attr(env.module, {:repeatable, bool})
  end

  @doc false
  # Record directive AST nodes in the current scope
  def record_locations!(env, locations) do
    locations = expand_ast(locations, env)
    put_attr(env.module, {:locations, List.wrap(locations)})
  end

  @doc false
  # Record a directive
  def record_directive!(env, identifier, attrs, block) do
    attrs =
      attrs
      |> Keyword.put(:identifier, identifier)
      |> Keyword.put_new(:name, to_string(identifier))
      |> Keyword.update(:description, nil, &wrap_in_unquote/1)

    scoped_def(env, Schema.DirectiveDefinition, identifier, attrs, block)
  end

  @doc false
  # Record a parse function in the current scope
  def record_parse!(env, fun_ast) do
    put_attr(env.module, {:parse, fun_ast})
  end

  @doc false
  # Record private values
  def record_private!(env, owner, keyword_list) when is_list(keyword_list) do
    keyword_list = expand_ast(keyword_list, env)

    put_attr(env.module, {:__private__, [{owner, keyword_list}]})
  end

  @doc false
  # Record a serialize function in the current scope
  def record_serialize!(env, fun_ast) do
    put_attr(env.module, {:serialize, fun_ast})
  end

  @doc false
  # Record a type checker in the current scope
  def record_is_type_of!(env, func_ast) do
    put_attr(env.module, {:is_type_of, func_ast})
    # :ok
  end

  @doc false
  # Record a complexity analyzer in the current scope
  def record_complexity!(env, func_ast) do
    put_attr(env.module, {:complexity, func_ast})
    # :ok
  end

  @doc false
  # Record a type resolver in the current scope
  def record_resolve_type!(env, func_ast) do
    put_attr(env.module, {:resolve_type, func_ast})
    # :ok
  end

  @doc false
  # Record an implemented interface in the current scope
  def record_interface!(env, identifier) do
    put_attr(env.module, {:interface, identifier})
    # Scope.put_attribute(env.module, :interfaces, identifier, accumulate: true)
    # Scope.recorded!(env.module, :attr, :interface)
    # :ok
  end

  @doc false
  # Record a deprecation in the current scope
  def record_deprecate!(env, msg) do
    msg = expand_ast(msg, env)

    record_applied_directive!(env, :deprecated, reason: msg)
  end

  @doc false
  # Record a list of implemented interfaces in the current scope
  def record_interfaces!(env, ifaces) do
    Enum.each(ifaces, &record_interface!(env, &1))
  end

  @doc false
  # Record a list of member types for a union in the current scope
  def record_types!(env, types) do
    put_attr(env.module, {:types, types})
  end

  @doc false
  # Record an enum type
  def record_enum!(env, identifier, attrs, block) do
    attrs = expand_ast(attrs, env)
    attrs = Keyword.put(attrs, :identifier, identifier)
    scoped_def(env, :enum, identifier, attrs, block)
  end

  @doc false
  # Record a description in the current scope
  def record_description!(env, text_block) do
    text = wrap_in_unquote(text_block)

    put_attr(env.module, {:desc, text})
  end

  @doc false
  # Record a scalar
  def record_scalar!(env, identifier, attrs, block_or_nil) do
    record!(
      env,
      Schema.ScalarTypeDefinition,
      identifier,
      attrs |> Keyword.update(:description, nil, &wrap_in_unquote/1),
      block_or_nil
    )
  end

  def handle_enum_value_attrs(identifier, raw_attrs, env) do
    value = Keyword.get(raw_attrs, :as, identifier)

    block =
      for {identifier, args} <- build_directives(raw_attrs) do
        quote do
          directive(unquote(identifier), unquote(args))
        end
      end

    attrs =
      raw_attrs
      |> expand_ast(env)
      |> Keyword.delete(:directives)
      |> Keyword.put(:identifier, identifier)
      |> Keyword.put(:value, wrap_in_unquote(value))
      |> Keyword.put_new(:name, String.upcase(to_string(identifier)))
      |> Keyword.delete(:as)
      |> Keyword.delete(:deprecate)
      |> Keyword.update(:description, nil, &wrap_in_unquote/1)

    {attrs, block}
  end

  @doc false
  # Record an enum value in the current scope
  def record_value!(env, identifier, raw_attrs) do
    {attrs, block} = handle_enum_value_attrs(identifier, raw_attrs, env)
    record!(env, Schema.EnumValueDefinition, identifier, attrs, block)
  end

  @doc false
  # Record an enum value in the current scope
  def record_values!(env, values) do
    values =
      values
      |> expand_ast(env)
      |> wrap_in_unquote

    put_attr(env.module, {:values, values})
  end

  def record_config!(env, fun_ast) do
    put_attr(env.module, {:config, fun_ast})
  end

  def record_trigger!(env, mutations, attrs) do
    for mutation <- mutations do
      put_attr(env.module, {:trigger, {mutation, attrs}})
    end
  end

  def record_applied_directive!(env, name, attrs) do
    name = Atom.to_string(name)

    attrs =
      attrs
      |> expand_ast(env)
      |> build_directive_arguments(env)
      |> Keyword.put(:name, name)
      |> put_reference(env)

    directive = struct!(Absinthe.Blueprint.Directive, attrs)
    put_attr(env.module, {:directive, directive})
  end

  defp build_directive_arguments(attrs, env) do
    arguments =
      attrs
      |> Enum.map(fn {name, value} ->
        value = expand_ast(value, env)

        attrs = [
          name: Atom.to_string(name),
          value: value,
          input_value: Absinthe.Blueprint.Input.Value.build(value),
          source_location: Absinthe.Blueprint.SourceLocation.at(env.line, 0)
        ]

        struct!(Absinthe.Blueprint.Input.Argument, attrs)
      end)

    [arguments: arguments]
  end

  def record_middleware!(env, new_middleware, opts) do
    new_middleware =
      case expand_ast(new_middleware, env) do
        {module, fun} ->
          {:{}, [], [{module, fun}, opts]}

        atom when is_atom(atom) ->
          case Atom.to_string(atom) do
            "Elixir." <> _ ->
              {:{}, [], [{atom, :call}, opts]}

            _ ->
              {:{}, [], [{env.module, atom}, opts]}
          end

        val ->
          val
      end

    put_attr(env.module, {:middleware, [new_middleware]})
  end

  # We wrap the value (from the user) in an `unquote` call, so that when the schema `blueprint` is
  # placed into `__absinthe_blueprint__` via `unquote(Macro.escape(blueprint, unquote: true))` the
  # value gets unquoted. This allows us to evaluate function calls in the scope of the schema
  # module.
  defp wrap_in_unquote(value) do
    {:unquote, [], [value]}
  end

  # ------------------------------

  @doc false
  defmacro pop() do
    module = __CALLER__.module
    popped = pop_stack(module, :absinthe_scope_stack_stash)
    push_stack(module, :absinthe_scope_stack, popped)
    put_attr(__CALLER__.module, :pop)
  end

  @doc false
  defmacro stash() do
    module = __CALLER__.module
    popped = pop_stack(module, :absinthe_scope_stack)
    push_stack(module, :absinthe_scope_stack_stash, popped)
    put_attr(module, :stash)
  end

  @doc false
  defmacro close_scope() do
    put_attr(__CALLER__.module, :close)
    pop_stack(__CALLER__.module, :absinthe_scope_stack)
  end

  def put_reference(attrs, env) do
    Keyword.put(attrs, :__reference__, build_reference(env))
  end

  def build_reference(env) do
    %{
      module: env.module,
      location: %{
        file: env.file,
        line: env.line
      }
    }
  end

  @scope_map %{
    Schema.ObjectTypeDefinition => :object,
    Schema.FieldDefinition => :field,
    Schema.ScalarTypeDefinition => :scalar,
    Schema.EnumTypeDefinition => :enum,
    Schema.EnumValueDefinition => :value,
    Schema.InputObjectTypeDefinition => :input_object,
    Schema.InputValueDefinition => :arg,
    Schema.UnionTypeDefinition => :union,
    Schema.InterfaceTypeDefinition => :interface,
    Schema.DirectiveDefinition => :directive
  }
  defp scoped_def(caller, type, identifier, attrs, body) do
    attrs =
      attrs
      |> Keyword.put(:identifier, identifier)
      |> Keyword.put_new(:name, default_name(type, identifier))
      |> Keyword.put(:module, caller.module)
      |> put_reference(caller)

    definition = struct!(type, attrs)

    ref = put_attr(caller.module, definition)

    push_stack(caller.module, :absinthe_scope_stack, Map.fetch!(@scope_map, type))

    [
      get_desc(ref),
      body,
      quote(do: unquote(__MODULE__).close_scope())
    ]
  end

  defp get_desc(ref) do
    quote do
      unquote(__MODULE__).put_desc(__MODULE__, unquote(ref))
    end
  end

  defp push_stack(module, key, val) do
    stack = Module.get_attribute(module, key)
    stack = [val | stack]
    Module.put_attribute(module, key, stack)
  end

  defp pop_stack(module, key) do
    [popped | stack] = Module.get_attribute(module, key)
    Module.put_attribute(module, key, stack)
    popped
  end

  def put_attr(module, thing) do
    ref = :erlang.unique_integer()
    Module.put_attribute(module, :absinthe_blueprint, {ref, thing})
    ref
  end

  defp default_name(Schema.FieldDefinition, identifier) do
    identifier
    |> Atom.to_string()
  end

  defp default_name(_, identifier) do
    identifier
    |> Atom.to_string()
    |> Absinthe.Utils.camelize()
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

  @spec do_import_sdl(Macro.Env.t(), nil | String.t() | Macro.t(), [import_sdl_option()]) ::
          Macro.t()
  defp do_import_sdl(env, nil, opts) do
    case Keyword.fetch(opts, :path) do
      {:ok, path} ->
        [
          quote do
            @__absinthe_import_sdl_path__ unquote(path)
          end,
          do_import_sdl(
            env,
            quote do
              File.read!(@__absinthe_import_sdl_path__)
            end,
            opts
          ),
          quote do
            @external_resource @__absinthe_import_sdl_path__
          end
        ]

      :error ->
        raise Absinthe.Schema.Notation.Error,
              "Must provide `:path` option to `import_sdl` unless passing a raw SDL string as the first argument"
    end
  end

  defp do_import_sdl(env, sdl, opts) do
    ref = build_reference(env)

    quote do
      with {:ok, definitions} <-
             unquote(__MODULE__).SDL.parse(
               unquote(sdl),
               __MODULE__,
               unquote(Macro.escape(ref)),
               unquote(Macro.escape(opts))
             ) do
        @__absinthe_sdl_definitions__ definitions ++
                                        (Module.get_attribute(
                                           __MODULE__,
                                           :__absinthe_sdl_definitions__
                                         ) || [])
      else
        {:error, error} ->
          raise Absinthe.Schema.Notation.Error, "`import_sdl` could not parse SDL:\n#{error}"
      end
    end
  end

  def put_desc(module, ref) do
    Module.put_attribute(module, :absinthe_desc, {ref, Module.get_attribute(module, :desc)})
    Module.put_attribute(module, :desc, nil)
  end

  def noop(_desc) do
    :ok
  end

  defmacro __before_compile__(env) do
    module_attribute_descs =
      env.module
      |> Module.get_attribute(:absinthe_desc)
      |> Map.new()

    attrs =
      env.module
      |> Module.get_attribute(:absinthe_blueprint)
      |> List.insert_at(0, :close)
      |> reverse_with_descs(module_attribute_descs)

    imports =
      (Module.get_attribute(env.module, :__absinthe_type_imports__) || [])
      |> Enum.uniq()
      |> Enum.map(fn
        module when is_atom(module) -> {module, []}
        other -> other
      end)

    schema_def = %Schema.SchemaDefinition{
      imports: imports,
      module: env.module,
      __reference__: %{
        location: %{file: env.file, line: 0}
      }
    }

    blueprint =
      attrs
      |> List.insert_at(1, schema_def)
      |> Absinthe.Blueprint.Schema.build()

    # TODO: handle multiple schemas
    [schema] = blueprint.schema_definitions

    {schema, functions} = lift_functions(schema, env.module)

    sdl_definitions =
      (Module.get_attribute(env.module, :__absinthe_sdl_definitions__) || [])
      |> List.flatten()
      |> Enum.map(fn definition ->
        Absinthe.Blueprint.prewalk(definition, fn
          %{module: _} = node ->
            %{node | module: env.module}

          node ->
            node
        end)
      end)

    {sdl_directive_definitions, sdl_type_definitions} =
      Enum.split_with(sdl_definitions, fn
        %Absinthe.Blueprint.Schema.DirectiveDefinition{} ->
          true

        _ ->
          false
      end)

    schema =
      schema
      |> Map.update!(:type_definitions, &(sdl_type_definitions ++ &1))
      |> Map.update!(:directive_definitions, &(sdl_directive_definitions ++ &1))

    blueprint = %{blueprint | schema_definitions: [schema]}

    quote do
      unquote(__MODULE__).noop(@desc)

      def __absinthe_blueprint__ do
        unquote(Macro.escape(blueprint, unquote: true))
      end

      unquote_splicing(functions)
    end
  end

  def lift_functions(schema, origin) do
    Absinthe.Blueprint.prewalk(schema, [], &lift_functions(&1, &2, origin))
  end

  def lift_functions(node, acc, origin) do
    {node, ast} = functions_for_type(node, origin)
    {node, ast ++ acc}
  end

  defp functions_for_type(%Schema.FieldDefinition{} = type, origin) do
    grab_functions(
      origin,
      type,
      {Schema.FieldDefinition, type.function_ref},
      Schema.functions(Schema.FieldDefinition)
    )
  end

  defp functions_for_type(%module{identifier: identifier} = type, origin) do
    grab_functions(origin, type, {module, identifier}, Schema.functions(module))
  end

  defp functions_for_type(type, _) do
    {type, []}
  end

  def grab_functions(origin, type, identifier, attrs) do
    {ast, type} =
      Enum.flat_map_reduce(attrs, type, fn attr, type ->
        value = Map.fetch!(type, attr)

        ast =
          quote do
            def __absinthe_function__(unquote(identifier), unquote(attr)) do
              unquote(value)
            end
          end

        ref = {:ref, origin, identifier}

        type =
          Map.update!(type, attr, fn
            value when is_list(value) ->
              [ref]

            _ ->
              ref
          end)

        {[ast], type}
      end)

    {type, ast}
  end

  @doc false
  def __ensure_middleware__([], _field, %{identifier: :subscription}) do
    [Absinthe.Middleware.PassParent]
  end

  def __ensure_middleware__([], %{identifier: identifier}, _) do
    [{Absinthe.Middleware.MapGet, identifier}]
  end

  # Don't install Telemetry middleware for Introspection fields
  @introspection [Absinthe.Phase.Schema.Introspection, Absinthe.Type.BuiltIns.Introspection]
  def __ensure_middleware__(middleware, %{definition: definition}, _object)
      when definition in @introspection do
    middleware
  end

  # Install Telemetry middleware
  def __ensure_middleware__(middleware, _field, _object) do
    [{Absinthe.Middleware.Telemetry, []} | middleware]
  end

  defp reverse_with_descs(attrs, descs, acc \\ [])

  defp reverse_with_descs([], _descs, acc), do: acc

  defp reverse_with_descs([{ref, attr} | rest], descs, acc) do
    if desc = Map.get(descs, ref) do
      reverse_with_descs(rest, descs, [attr, {:desc, desc} | acc])
    else
      reverse_with_descs(rest, descs, [attr | acc])
    end
  end

  defp reverse_with_descs([attr | rest], descs, acc) do
    reverse_with_descs(rest, descs, [attr | acc])
  end

  defp expand_ast(ast, env) do
    Macro.prewalk(ast, fn
      # We don't want to expand `@bla` into `Module.get_attribute(module, @bla)` because this
      # function call will fail if the module is already compiled. Remember that the ast gets put
      # into a generated `__absinthe_blueprint__` function which is called at "__after_compile__"
      # time. This will be after a module has been compiled if there are multiple modules in the
      # schema (in the case of an `import_types`).
      #
      # Also see test "test/absinthe/type/import_types_test.exs"
      # "__absinthe_blueprint__ is callable at runtime even if there is a module attribute"
      # and it's comment for more information
      {:@, _, _} = node ->
        node

      {_, _, _} = node ->
        Macro.expand(node, env)

      node ->
        node
    end)
  end

  @doc false
  # Ensure the provided operation can be recorded in the current environment,
  # in the current scope context
  def recordable!(env, usage, placement) do
    [scope | _] = Module.get_attribute(env.module, :absinthe_scope_stack)

    unless recordable?(placement, scope) do
      raise Absinthe.Schema.Notation.Error, invalid_message(placement, usage, scope)
    end

    env
  end

  defp recordable?([under: under], scope), do: scope in under
  defp recordable?([toplevel: true], scope), do: scope == :schema
  defp recordable?([toplevel: false], scope), do: scope != :schema

  defp invalid_message([under: under], usage, scope) do
    allowed = under |> Enum.map(&"`#{&1}`") |> Enum.join(", ")

    "Invalid schema notation: `#{usage}` must only be used within #{allowed}. #{used_in(scope)}"
  end

  defp invalid_message([toplevel: true], usage, scope) do
    "Invalid schema notation: `#{usage}` must only be used toplevel. #{used_in(scope)}"
  end

  defp invalid_message([toplevel: false], usage, scope) do
    "Invalid schema notation: `#{usage}` must not be used toplevel. #{used_in(scope)}"
  end

  defp used_in(scope) do
    scope = Atom.to_string(scope)
    "Was used in `#{scope}`."
  end
end
