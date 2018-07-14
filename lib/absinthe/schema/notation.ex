defmodule Absinthe.Schema.Notation do
  @moduledoc """
  This module contains macros used to build GraphQL types.

  See `Absinthe.Schema` for a rough overview of schema building from scratch.
  """

  alias Absinthe.Utils
  alias Absinthe.Type
  alias Absinthe.Schema.Notation.Scope

  defmacro __using__(opts \\ []) do
    import_opts = opts |> Keyword.put(:only, :macros)
    Module.register_attribute(__CALLER__.module, :absinthe_definitions, accumulate: true)
    Module.register_attribute(__CALLER__.module, :absinthe_descriptions, accumulate: true)

    quote do
      import Absinthe.Resolution.Helpers,
        only: [
          async: 1,
          async: 2,
          batch: 3,
          batch: 4
        ]

      import unquote(__MODULE__), unquote(import_opts)
      @before_compile unquote(__MODULE__).Writer
      @desc nil
    end
  end

  Module.register_attribute(__MODULE__, :placement, accumulate: true)

  @doc false
  # Return a quote that records the current @desc value for a given identifier
  def desc_attribute_recorder(identifier) do
    quote do
      @absinthe_descriptions {unquote(identifier), @desc}
      @desc nil
    end
  end

  @doc false
  defmacro resolver(_) do
    raise "`resolver/1` is not a function, did you mean `resolve` ?"
  end

  @placement {:config, [under: [:field]]}
  @doc """
  Configure a subscription field.

  ## Example

  ```elixir
  config fn args, %{context: context} ->
    if authorized?(context) do
      {:ok, topic: args.client_id}
    else
      {:error, "unauthorized"}
    end
  end
  ```

  See `Absinthe.Schema.subscription/1` for details
  """
  defmacro config(config_fun) do
    env = __CALLER__
    recordable!(env, :config, @placement[:config])
    Scope.put_attribute(env.module, :config, config_fun)
    []
  end

  @placement {:trigger, [under: [:field]]}
  @doc """
  Set a trigger for a subscription field.

  It accepts one or more mutation field names, and can be called more than once.

  ```
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

      trigger :gps_event, topic: fn event ->
        event.user_id
      end

      trigger :user_checkin, topic: fn user ->
        [user.id, user.parent_id]
      end
    end
  end
  ```

  Trigger functions are only called once per event, so database calls within
  them do not present a significant burden.

  See the `subscription/2` macro docs for additional details
  """
  defmacro trigger(mutations, attrs) do
    env = __CALLER__
    recordable!(env, :trigger, @placement[:trigger])
    Scope.put_attribute(env.module, :triggers, {List.wrap(mutations), attrs}, accumulate: true)
    :ok
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
          "Invalid schema notation: cannot create an `object` with reserved identifier `#{
            identifier
          }`"
  end

  defmacro object(identifier, attrs, do: block) do
    __CALLER__
    |> recordable!(:object, @placement[:object])
    |> record_object!(identifier, attrs, block)

    desc_attribute_recorder(identifier)
  end

  def record_object!(env, identifier, attrs, block) do
    attrs = Keyword.put(attrs, :identifier, identifier)
    scope(env, :object, identifier, attrs, block)
  end

  @placement {:interfaces, [under: :object]}
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

  @doc false
  # Record a list of implemented interfaces in the current scope
  def record_interfaces!(env, ifaces) do
    Enum.each(ifaces, &record_interface!(env, &1))
    :ok
  end

  @placement {:resolve, [under: [:field]]}
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

  @doc false
  # Record a deprecation in the current scope
  def record_deprecate!(env, msg) do
    Scope.put_attribute(env.module, :deprecate, msg)
    :ok
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
  @placement {:interface_attribute, [under: :object]}
  defmacro interface(identifier) do
    __CALLER__
    |> recordable!(
      :interface_attribute,
      @placement[:interface_attribute],
      as: "`interface` (as an attribute)"
    )
    |> record_interface!(identifier)
  end

  @doc false
  # Record an implemented interface in the current scope
  def record_interface!(env, identifier) do
    Scope.put_attribute(env.module, :interfaces, identifier, accumulate: true)
    Scope.recorded!(env.module, :attr, :interface)
    :ok
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
    |> record_interface!(identifier, attrs, block)

    desc_attribute_recorder(identifier)
  end

  @doc false
  # Record an interface type
  def record_interface!(env, identifier, attrs, block) do
    attrs = Keyword.put(attrs, :identifier, identifier)
    scope(env, :interface, identifier, attrs, block)
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

  @doc false
  # Record a type resolver in the current scope
  def record_resolve_type!(env, func_ast) do
    Scope.put_attribute(env.module, :resolve_type, func_ast)
    Scope.recorded!(env.module, :attr, :resolve_type)
    :ok
  end

  # FIELDS
  @placement {:field, [under: [:input_object, :interface, :object]]}
  @doc """
  Defines a GraphQL field

  See `field/4`
  """
  defmacro field(identifier, do: block) do
    __CALLER__
    |> recordable!(:field, @placement[:field])
    |> record_field!(identifier, [], block)
  end

  defmacro field(identifier, attrs) when is_list(attrs) do
    __CALLER__
    |> recordable!(:field, @placement[:field])
    |> record_field!(identifier, attrs, nil)
  end

  defmacro field(identifier, type) do
    __CALLER__
    |> recordable!(:field, @placement[:field])
    |> record_field!(identifier, [type: type], nil)
  end

  @doc """
  Defines a GraphQL field

  See `field/4`
  """
  defmacro field(identifier, attrs, do: block) when is_list(attrs) do
    __CALLER__
    |> recordable!(:field, @placement[:field])
    |> record_field!(identifier, attrs, block)
  end

  defmacro field(identifier, type, do: block) do
    __CALLER__
    |> recordable!(:field, @placement[:field])
    |> record_field!(identifier, [type: type], block)
  end

  defmacro field(identifier, type, attrs) do
    __CALLER__
    |> recordable!(:field, @placement[:field])
    |> record_field!(identifier, Keyword.put(attrs, :type, type), nil)
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
    __CALLER__
    |> recordable!(:field, @placement[:field])
    |> record_field!(identifier, Keyword.put(attrs, :type, type), block)
  end

  @doc false
  # Record a field in the current scope
  def record_field!(env, identifier, attrs, block) do
    scope(env, :field, identifier, attrs, block)
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

  @doc false
  # Record a resolver in the current scope
  def record_resolve!(env, func_ast) do
    Scope.put_attribute(env.module, :resolve, func_ast)
    Scope.recorded!(env.module, :attr, :resolve)
    :ok
  end

  @placement {:complexity, [under: [:field]]}
  defmacro complexity(func_ast) do
    __CALLER__
    |> recordable!(:complexity, @placement[:complexity])
    |> record_complexity!(func_ast)
  end

  @doc false
  # Record a complexity analyzer in the current scope
  def record_complexity!(env, func_ast) do
    Scope.put_attribute(env.module, :complexity, func_ast)
    Scope.recorded!(env.module, :attr, :complexity)
    :ok
  end

  @placement {:middleware, [under: [:field]]}
  defmacro middleware(new_middleware, opts \\ []) do
    env = __CALLER__

    new_middleware = Macro.expand(new_middleware, env)

    middleware =
      Scope.current(env.module).attrs
      |> Keyword.get(:middleware, [])

    new_middleware =
      case new_middleware do
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

    Scope.put_attribute(env.module, :middleware, [new_middleware | middleware])
    nil
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

  @doc false
  # Record a type checker in the current scope
  def record_is_type_of!(env, func_ast) do
    Scope.put_attribute(env.module, :is_type_of, func_ast)
    Scope.recorded!(env.module, :attr, :is_type_of)
    :ok
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
    arg :name, :string, description: "The desired name"
  end
  ```
  """
  defmacro arg(identifier, type, attrs) do
    __CALLER__
    |> recordable!(:arg, @placement[:arg])
    |> record_arg!(identifier, Keyword.put(attrs, :type, type), nil)
  end

  @doc """
  Add an argument.

  See `arg/3`
  """
  defmacro arg(identifier, attrs) when is_list(attrs) do
    __CALLER__
    |> recordable!(:arg, @placement[:arg])
    |> record_arg!(identifier, attrs, nil)
  end

  defmacro arg(identifier, type) do
    __CALLER__
    |> recordable!(:arg, @placement[:arg])
    |> record_arg!(identifier, [type: type], nil)
  end

  @doc false
  # Record an argument in the current scope
  def record_arg!(env, identifier, attrs, block) do
    scope(env, :arg, identifier, attrs, block)
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

    desc_attribute_recorder(identifier)
  end

  @doc """
  Defines a scalar type

  See `scalar/3`
  """
  defmacro scalar(identifier, do: block) do
    __CALLER__
    |> recordable!(:scalar, @placement[:scalar])
    |> record_scalar!(identifier, [], block)

    desc_attribute_recorder(identifier)
  end

  defmacro scalar(identifier, attrs) do
    __CALLER__
    |> recordable!(:scalar, @placement[:scalar])
    |> record_scalar!(identifier, attrs, nil)

    desc_attribute_recorder(identifier)
  end

  @doc false
  # Record a scalar type
  def record_scalar!(env, identifier, attrs, block) do
    attrs = Keyword.put(attrs, :identifier, identifier)
    scope(env, :scalar, identifier, attrs, block)
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

  @doc false
  # Record a serialize function in the current scope
  def record_serialize!(env, func_ast) do
    Scope.put_attribute(env.module, :serialize, func_ast)
    Scope.recorded!(env.module, :attr, :serialize)
    :ok
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

  @doc false
  # Record private values
  def record_private!(env, owner, keyword_list) when is_list(keyword_list) do
    owner = expand(owner, env)
    keyword_list = expand(keyword_list, env)

    keyword_list
    |> Enum.each(fn {k, v} -> do_record_private!(env, owner, k, v) end)
  end

  defp do_record_private!(env, owner, key, value) do
    new_attrs =
      Scope.current(env.module).attrs
      |> Keyword.put_new(:__private__, [])
      |> update_in([:__private__, owner], &List.wrap(&1))
      |> put_in([:__private__, owner, key], value)

    Scope.put_attribute(env.module, :__private__, new_attrs[:__private__])
    :ok
  end

  @placement {:parse, [under: [:scalar]]}
  @doc """
  Defines a parse function for a `scalar` type

  The specified `parse` function is used on incoming data to transform it into
  an elixir datastructure.

  It should return `{:ok, value}` or `{:error, reason}`

  ## Placement

  #{Utils.placement_docs(@placement)}
  """
  defmacro parse(func_ast) do
    __CALLER__
    |> recordable!(:parse, @placement[:parse])
    |> record_parse!(func_ast)

    []
  end

  @doc false
  # Record a parse function in the current scope
  def record_parse!(env, func_ast) do
    Scope.put_attribute(env.module, :parse, func_ast)
    Scope.recorded!(env.module, :attr, :parse)
    :ok
  end

  # DIRECTIVES

  @placement {:directive, [toplevel: true]}
  @doc """
  Defines a directive

  ## Placement

  #{Utils.placement_docs(@placement)}

  ## Examples

  ```
  directive :mydirective do

    arg :if, non_null(:boolean), description: "Skipped when true."

    on Language.FragmentSpread
    on Language.Field
    on Language.InlineFragment

    instruction fn
      %{if: true} ->
        :skip
      _ ->
        :include
    end

  end
  ```
  """
  defmacro directive(identifier, attrs \\ [], do: block) do
    __CALLER__
    |> recordable!(:directive, @placement[:directive])
    |> record_directive!(identifier, attrs, block)

    desc_attribute_recorder(identifier)
  end

  @doc false
  # Record a directive
  def record_directive!(env, identifier, attrs, block) do
    attrs = Keyword.put(attrs, :identifier, identifier)
    scope(env, :directive, identifier, attrs, block)
  end

  @placement {:on, [under: :directive]}
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

  @doc false
  # Record directive AST nodes in the current scope
  def record_locations!(env, ast_node) do
    ast_node
    |> List.wrap()
    |> Enum.each(fn value ->
      Scope.put_attribute(
        env.module,
        :locations,
        value,
        accumulate: true
      )

      Scope.recorded!(env.module, :attr, :locations)
    end)

    :ok
  end

  @placement {:instruction, [under: :directive]}
  @doc """
  Calculate the instruction for a directive

  ## Placement

  #{Utils.placement_docs(@placement)}
  """
  defmacro instruction(func_ast) do
    __CALLER__
    |> recordable!(:instruction, @placement[:instruction])
    |> record_instruction!(func_ast)
  end

  @doc false
  # Record a directive instruction function in the current scope
  def record_instruction!(env, func_ast) do
    Scope.put_attribute(env.module, :instruction, func_ast)
    Scope.recorded!(env.module, :attr, :instruction)
    :ok
  end

  @placement {:expand, [under: :directive]}
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

  @doc false
  # Record a directive expand function in the current scope
  def record_expand!(env, func_ast) do
    Scope.put_attribute(env.module, :expand, func_ast)
    Scope.recorded!(env.module, :attr, :expand)
    :ok
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
    |> record_input_object!(identifier, attrs, block)

    desc_attribute_recorder(identifier)
  end

  @doc false
  # Record an input object type
  def record_input_object!(env, identifier, attrs, block) do
    attrs = Keyword.put(attrs, :identifier, identifier)
    scope(env, :input_object, identifier, attrs, block)
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
    |> record_union!(identifier, attrs, block)

    desc_attribute_recorder(identifier)
  end

  @doc false
  # Record a union type
  def record_union!(env, identifier, attrs, block) do
    attrs = Keyword.put(attrs, :identifier, identifier)
    scope(env, :union, identifier, attrs, block)
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

  @doc false
  # Record a list of member types for a union in the current scope
  def record_types!(env, types) do
    Scope.put_attribute(env.module, :types, List.wrap(types))
    Scope.recorded!(env.module, :attr, :types)
    :ok
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
    __CALLER__
    |> recordable!(:enum, @placement[:enum])
    |> record_enum!(identifier, attrs, block)

    desc_attribute_recorder(identifier)
  end

  @doc """
  Defines an enum type

  See `enum/3`
  """
  defmacro enum(identifier, do: block) do
    __CALLER__
    |> recordable!(:enum, @placement[:enum])
    |> record_enum!(identifier, [], block)

    desc_attribute_recorder(identifier)
  end

  defmacro enum(identifier, attrs) do
    __CALLER__
    |> recordable!(:enum, @placement[:enum])
    |> record_enum!(identifier, attrs, nil)

    desc_attribute_recorder(identifier)
  end

  @doc false
  # Record an enum type
  def record_enum!(env, identifier, attrs, block) do
    attrs = expand(attrs, env)
    attrs = Keyword.put(attrs, :identifier, identifier)
    scope(env, :enum, identifier, attrs, block)
  end

  @placement {:value, [under: [:enum]]}
  @doc """
  Defines a value possible under an enum type

  See `enum/3`

  ## Placement

  #{Utils.placement_docs(@placement)}
  """
  defmacro value(identifier, raw_attrs \\ []) do
    __CALLER__
    |> recordable!(:value, @placement[:value])
    |> record_value!(identifier, raw_attrs)
  end

  @doc false
  # Record an enum value in the current scope
  def record_value!(env, identifier, raw_attrs) do
    attrs =
      raw_attrs
      |> Keyword.put(:value, Keyword.get(raw_attrs, :as, identifier))
      |> Keyword.delete(:as)
      |> add_description(env)

    Scope.put_attribute(env.module, :values, {identifier, attrs}, accumulate: true)
    Scope.recorded!(env.module, :attr, :value)
    :ok
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

  defp reformat_description(text), do: String.trim(text)

  @doc false
  # Record a description in the current scope
  def record_description!(env, text_block) do
    text = reformat_description(text_block)
    Scope.put_attribute(env.module, :description, text)
    Scope.recorded!(env.module, :attr, :description)
    :ok
  end

  # IMPORTS

  @placement {:import_types, [toplevel: true]}
  @doc """
  Import types from another module

  Very frequently your schema module will simply have the `query` and `mutation`
  blocks, and you'll want to break out your other types into other modules. This
  macro imports those types for use the current module

  ## Placement

  #{Utils.placement_docs(@placement)}

  ## Examples
  ```
  import_types MyApp.Schema.Types

  import_types MyApp.Schema.Types.{TypesA, TypesB, SubTypes.TypesC}
  ```
  """
  defmacro import_types(type_module_ast) do
    env = __CALLER__

    type_module_ast
    |> Macro.expand(env)
    |> do_import_types(env)

    :ok
  end

  defp do_import_types({{:., _, [root_ast, :{}]}, _, modules_ast_list}, env) do
    {:__aliases__, meta, root} = root_ast

    for {_, _, leaves} <- modules_ast_list do
      type_module = Macro.expand({:__aliases__, meta, root ++ leaves}, env)

      if Code.ensure_compiled?(type_module) do
        do_import_types(type_module, env)
      else
        raise ArgumentError, "module #{type_module} is not available"
      end
    end
  end

  defp do_import_types(type_module, env) when is_atom(type_module) do
    imports = Module.get_attribute(env.module, :absinthe_imports) || []
    _ = Module.put_attribute(env.module, :absinthe_imports, [type_module | imports])

    types =
      for {ident, name} <- type_module.__absinthe_types__,
          ident in type_module.__absinthe_exports__ do
        put_definition(env.module, %Absinthe.Schema.Notation.Definition{
          category: :type,
          source: type_module,
          identifier: ident,
          attrs: [name: name],
          file: env.file,
          line: env.line
        })

        ident
      end

    directives =
      for {ident, name} <- type_module.__absinthe_directives__,
          ident in type_module.__absinthe_exports__ do
        put_definition(env.module, %Absinthe.Schema.Notation.Definition{
          category: :directive,
          source: type_module,
          identifier: ident,
          attrs: [name: name],
          file: env.file,
          line: env.line
        })
      end

    {:ok, types: types, directives: directives}
  end

  defp do_import_types(type_module, _) do
    raise ArgumentError, """
    `#{Macro.to_string(type_module)}` is not a module

    This macro must be given a literal module name or a macro which expands to a
    literal module name. Variables are not supported at this time.
    """
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
  defmacro import_fields(type_name, opts \\ []) do
    __CALLER__
    |> recordable!(:import_fields, @placement[:import_fields])
    |> record_field_import!(type_name, opts)
  end

  defp record_field_import!(env, type_name, opts) do
    Scope.put_attribute(env.module, :field_imports, {type_name, opts}, accumulate: true)
  end

  # TYPE UTILITIES
  @doc """
  Marks a type reference as non null

  See `field/3` for examples
  """
  defmacro non_null(type) do
    quote do
      %Absinthe.Type.NonNull{of_type: unquote(type)}
    end
  end

  @doc """
  Marks a type reference as a list of the given type

  See `field/3` for examples
  """
  defmacro list_of(type) do
    quote do
      %Absinthe.Type.List{of_type: unquote(type)}
    end
  end

  # NOTATION UTILITIES

  defp handle_meta(attrs) do
    {meta, attrs} = Keyword.pop(attrs, :meta)

    if meta do
      Keyword.update(attrs, :__private__, [meta: meta], fn private ->
        Keyword.update(private, :meta, meta, fn existing_meta ->
          meta |> Enum.into(existing_meta)
        end)
      end)
    else
      attrs
    end
  end

  # Define a notation scope that will accept attributes
  @doc false
  def scope(env, kind, identifier, attrs, block) do
    attrs = attrs |> handle_meta
    open_scope(kind, env, identifier, attrs)

    # this is probably too simple for now.
    block |> expand(env)

    close_scope(kind, env, identifier)
    Scope.recorded!(env.module, kind, identifier)
  end

  defp expand(ast, env) do
    Macro.prewalk(ast, fn
      {:@, _, [{:desc, _, [desc]}]} ->
        Module.put_attribute(env.module, :__absinthe_desc__, desc)

      {_, _, _} = node ->
        Macro.expand(node, env)

      node ->
        node
    end)
  end

  @doc false
  # Add a `__reference__` to a generated struct
  def add_reference(attrs, env, identifier) do
    attrs
    |> Keyword.put(
      :__reference__,
      Macro.escape(%{
        module: env.module,
        identifier: identifier,
        location: %{
          file: env.file,
          line: env.line
        }
      })
    )
  end

  # After verifying it is valid in the current context, open a new notation
  # scope, setting any provided attributes.
  defp open_scope(kind, env, identifier, attrs) do
    attrs =
      attrs
      |> add_reference(env, identifier)
      |> add_description(env)

    Scope.open(kind, env.module, attrs)
  end

  defp add_description(attrs, env) do
    case Module.get_attribute(env.module, :__absinthe_desc__) do
      nil ->
        attrs

      desc ->
        desc = Macro.expand(desc, env)
        Module.put_attribute(env.module, :__absinthe_desc__, nil)
        Keyword.put(attrs, :description, reformat_description(desc))
    end
  end

  # CLOSE SCOPE HOOKS

  @unexported_identifiers ~w(query mutation subscription)a

  # Close the current scope and return the appropriate
  # quoted result for the type of operation.
  defp close_scope(:enum, env, identifier) do
    close_scope_and_define_type(Type.Enum, env, identifier)
  end

  defp close_scope(:object, env, identifier) do
    close_scope_and_define_type(
      Type.Object,
      env,
      identifier,
      export: !Enum.member?(@unexported_identifiers, identifier)
    )
  end

  defp close_scope(:interface, env, identifier) do
    close_scope_and_define_type(Type.Interface, env, identifier)
  end

  defp close_scope(:union, env, identifier) do
    close_scope_and_define_type(Type.Union, env, identifier)
  end

  defp close_scope(:input_object, env, identifier) do
    close_scope_and_define_type(Type.InputObject, env, identifier)
  end

  defp close_scope(:field, env, identifier) do
    close_scope_and_accumulate_attribute(:fields, env, identifier)
  end

  defp close_scope(:arg, env, identifier) do
    close_scope_and_accumulate_attribute(:args, env, identifier)
  end

  defp close_scope(:scalar, env, identifier) do
    close_scope_and_define_type(Type.Scalar, env, identifier)
  end

  defp close_scope(:directive, env, identifier) do
    close_scope_and_define_directive(env, identifier)
  end

  defp close_scope(_, env, _) do
    Scope.close(env)
  end

  defp close_scope_with_name(mod, identifier, opts \\ []) do
    Scope.close(mod).attrs
    |> add_name(identifier, opts)
  end

  defp close_scope_and_define_directive(env, identifier, def_opts \\ []) do
    definition = %Absinthe.Schema.Notation.Definition{
      category: :directive,
      builder: Absinthe.Type.Directive,
      identifier: identifier,
      attrs: close_scope_with_name(env.module, identifier),
      opts: def_opts,
      file: env.file,
      line: env.line
    }

    put_definition(env.module, definition)
  end

  defp close_scope_and_define_type(type_module, env, identifier, def_opts \\ []) do
    attrs = close_scope_with_name(env.module, identifier, title: true)

    definition = %Absinthe.Schema.Notation.Definition{
      category: :type,
      builder: type_module,
      identifier: identifier,
      attrs: attrs,
      opts: def_opts,
      file: env.file,
      line: env.line
    }

    put_definition(env.module, definition)
  end

  defp put_definition(module, definition) do
    Module.put_attribute(module, :absinthe_definitions, definition)
  end

  defp close_scope_and_accumulate_attribute(attr_name, env, identifier) do
    Scope.put_attribute(
      env.module,
      attr_name,
      {identifier, close_scope_with_name(env.module, identifier)},
      accumulate: true
    )
  end

  @doc false
  # Add the default name, if needed, to a struct
  def add_name(attrs, identifier, opts \\ []) do
    update_in(attrs, [:name], fn value ->
      default_name(identifier, value, opts)
    end)
  end

  # Find the name, or default as necessary
  defp default_name(identifier, nil, opts) do
    if opts[:title] do
      identifier |> Atom.to_string() |> Utils.camelize()
    else
      identifier |> Atom.to_string()
    end
  end

  defp default_name(_, name, _) do
    name
  end

  @doc false
  # Get a value at a path
  @spec get_in_private(atom, [atom]) :: any
  def get_in_private(mod, path) do
    Enum.find_value(Scope.on(mod), fn %{attrs: attrs} ->
      get_in(attrs, [:__private__ | path])
    end)
  end

  @doc false
  # Ensure the provided operation can be recorded in the current environment,
  # in the current scope context
  def recordable!(env, usage) do
    recordable!(env, usage, Keyword.get(@placement, usage, []))
  end

  def recordable!(env, usage, kw_rules, opts \\ []) do
    do_recordable!(env, usage, Enum.into(List.wrap(kw_rules), %{}), opts)
  end

  defp do_recordable!(env, usage, %{under: parents} = rules, opts) do
    case Scope.current(env.module) do
      %{name: name} ->
        if Enum.member?(List.wrap(parents), name) do
          do_recordable!(env, usage, Map.delete(rules, :under), opts)
        else
          raise Absinthe.Schema.Notation.Error, only_within(usage, parents, opts)
        end

      _ ->
        raise Absinthe.Schema.Notation.Error, only_within(usage, parents, opts)
    end
  end

  defp do_recordable!(env, usage, %{toplevel: true} = rules, opts) do
    case Scope.current(env.module) do
      nil ->
        do_recordable!(env, usage, Map.delete(rules, :toplevel), opts)

      _ ->
        ref = opts[:as] || "`#{usage}`"

        raise Absinthe.Schema.Notation.Error,
              "Invalid schema notation: #{ref} must only be used toplevel"
    end
  end

  defp do_recordable!(env, usage, %{toplevel: false} = rules, opts) do
    case Scope.current(env.module) do
      nil ->
        ref = opts[:as] || "`#{usage}`"

        raise Absinthe.Schema.Notation.Error,
              "Invalid schema notation: #{ref} must not be used toplevel"

      _ ->
        do_recordable!(env, usage, Map.delete(rules, :toplevel), opts)
    end
  end

  defp do_recordable!(env, usage, %{private_lookup: address} = rules, opts)
       when is_list(address) do
    case get_in_private(env.module, address) do
      nil ->
        ref = opts[:as] || "`#{usage}`"

        message =
          "Invalid schema notation: #{ref} failed a private value lookup for `#{
            address |> List.last()
          }'"

        raise Absinthe.Schema.Notation.Error, message

      _ ->
        do_recordable!(env, usage, Map.delete(rules, :private_lookup), opts)
    end
  end

  defp do_recordable!(env, _, rules, _) when map_size(rules) == 0 do
    env
  end

  @doc false
  # Get the placement information for a macro
  @spec placement(atom) :: Keyword.t()
  def placement(usage) do
    Keyword.get(@placement, usage, [])
  end

  # The error message when a macro can only be used within a certain set of
  # parent scopes.
  defp only_within(usage, parents, opts) do
    ref = opts[:as] || "`#{usage}`"

    parts =
      List.wrap(parents)
      |> Enum.map(&"`#{&1}`")
      |> Enum.join(", ")

    "Invalid schema notation: #{ref} must only be used within #{parts}"
  end
end
