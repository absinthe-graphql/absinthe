defmodule Absinthe.Schema.Notation do

  @moduledoc """
  This module contains macros used to build GraphQL types.

  See `Absinthe.Schema` for a rough overview of schema building from scratch.
  """

  alias Absinthe.Utils
  alias Absinthe.Type
  alias Absinthe.Schema.Notation.Scope

  defmacro __using__(_opts) do
    quote do
      import unquote(__MODULE__), only: :macros
      Module.register_attribute __MODULE__, :absinthe_definitions, accumulate: true
      Module.register_attribute(__MODULE__, :absinthe_descriptions, accumulate: true)
      @before_compile unquote(__MODULE__).Writer
      @desc nil
    end
  end

  Module.register_attribute(__MODULE__, :placement, accumulate: true)

  defp handle_desc(identifier) do
    quote do
      @absinthe_descriptions {unquote(identifier), @desc}
      @desc nil
    end
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
  defmacro object(identifier, attrs \\ [], [do: block]) do
    env = __CALLER__
    check_placement!(env.module, :object, @placement[:object])
    scope(env, :object, identifier, attrs, block)
    handle_desc(identifier)
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
    env = __CALLER__
    check_placement!(env.module, :interfaces, @placement[:interfaces])
    Scope.put_attribute(env.module, :interfaces, ifaces)
    []
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
    env = __CALLER__
    check_placement!(env.module, :deprecate, @placement[:deprecate])
    Scope.put_attribute(env.module, :deprecate, msg)
    []
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
    env = __CALLER__
    check_placement!(env.module, :interface_attribute, @placement[:interface_attribute], as: "`interface` (as an attribute)")
    Scope.put_attribute(env.module, :interfaces, identifier, accumulate: true)
    []
  end

  # INTERFACES

  @placement {:interface, [toplevel: :true]}
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
  defmacro interface(identifier, attrs \\ [], [do: block]) do
    env = __CALLER__
    check_placement!(env.module, :interface, @placement[:interface])
    scope(env, :interface, identifier, attrs, block)
    handle_desc(identifier)
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
    env = __CALLER__
    check_placement!(env.module, :resolve_type, @placement[:resolve_type])
    Scope.put_attribute(env.module, :resolve_type, func_ast)
    []
  end

  # FIELDS
  @placement {:field, [under: [:input_object, :interface, :object]]}
  @doc """
  Defines a GraphQL field

  See `field/4`
  """
  defmacro field(identifier, [do: block]) do
    env = __CALLER__
    check_placement!(env.module, :field, @placement[:field])
    scope(env, :field, identifier, [], block)
  end
  defmacro field(identifier, attrs) when is_list(attrs) do
    env = __CALLER__
    check_placement!(env.module, :field, @placement[:field])
    scope(env, :field, identifier, attrs, nil)
  end
  defmacro field(identifier, type) do
    env = __CALLER__
    check_placement!(env.module, :field, @placement[:field])
    scope(env, :field, identifier, [type: type], nil)
  end
  @doc """
  Defines a GraphQL field

  See `field/4`
  """
  defmacro field(identifier, attrs, [do: block]) when is_list(attrs) do
    env = __CALLER__
    check_placement!(env.module, :field, @placement[:field])
    scope(env, :field, identifier, attrs, block)
  end
  defmacro field(identifier, type, [do: block]) do
    env = __CALLER__
    check_placement!(env.module, :field, @placement[:field])
    scope(env, :field, identifier, [type: type], block)
  end
  defmacro field(identifier, type, attrs) do
    env = __CALLER__
    check_placement!(env.module, :field, @placement[:field])
    scope(env, :field, identifier, Keyword.put(attrs, :type, type),  nil)
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
  defmacro field(identifier, type, attrs, [do: block]) do
    env = __CALLER__
    check_placement!(env.module, :field, @placement[:field])
    scope(env, :field, identifier, Keyword.put(attrs, :type, type), block)
  end

  @placement {:resolve, [under: [:field]]}
  @doc """
  Defines a resolve function for a field

  Specify a 2 arity function to call when resolving a field. Resolve functions
  must return either `{:ok, term}` or `{:error, binary | [binary, ...]}`.

  You can either hard code a particular anonymous function, or have a function
  call that returns a 2 arity anonymous function. See examples for more information.

  The first argument to the function are the GraphQL arguments, and the latter
  is an `Absinthe.Execution.Field` struct. It is where you can access the GraphQL
  context and other execution data.

  Note that when using a hard coded anonymous function, the function will not
  capture local variables.

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
        Person.find(id)
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
      Person.find(id)
    end
  end
  ```
  """
  defmacro resolve(func_ast) do
    env = __CALLER__
    check_placement!(env.module, :resolve, @placement[:resolve])
    Scope.put_attribute(env.module, :resolve, func_ast)
    []
  end

  @placement {:is_type_of, [under: [:object]]}
  @doc """


  ## Placement

  #{Utils.placement_docs(@placement)}
  """
  defmacro is_type_of(func_ast) do
    env = __CALLER__
    check_placement!(env.module, :is_type_of, @placement[:is_type_of])
    Scope.put_attribute(env.module, :is_type_of, func_ast)
    []
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
    env = __CALLER__
    check_placement!(env.module, :arg, @placement[:arg])
    scope(env, :arg, identifier, Keyword.put(attrs, :type, type), nil)
  end

  @doc """
  Add an argument.

  See `arg/3`
  """
  defmacro arg(identifier, attrs) when is_list(attrs) do
    env = __CALLER__
    check_placement!(env.module, :arg, @placement[:arg])
    scope(env, :arg, identifier, attrs, nil)
  end
  defmacro arg(identifier, type) do
    env = __CALLER__
    check_placement!(env.module, :arg, @placement[:arg])
    scope(env, :arg, identifier, [type: type], nil)
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
  scalar :time do
    description "ISOz time"
    parse &Timex.DateFormat.parse(&1, "{ISOz}")
    serialize &Timex.DateFormat.format!(&1, "{ISOz}")
  end
  ```
  """
  defmacro scalar(identifier, attrs, [do: block]) do
    env = __CALLER__
    check_placement!(env.module, :scalar, @placement[:scalar])
    scope(env, :scalar, identifier, attrs, block)
    handle_desc(identifier)
  end

  @doc """
  Defines a scalar type

  See `scalar/3`
  """
  defmacro scalar(identifier, [do: block]) do
    env = __CALLER__
    check_placement!(env.module, :scalar, @placement[:scalar])
    scope(env, :scalar, identifier, [], block)
    handle_desc(identifier)
  end
  defmacro scalar(identifier, attrs) do
    env = __CALLER__
    check_placement!(env.module, :scalar, @placement[:scalar])
    scope(env, :scalar, identifier, attrs, nil)
    handle_desc(identifier)
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
    env = __CALLER__
    check_placement!(env.module, :serialize, @placement[:serialize])
    Scope.put_attribute(env.module, :serialize, func_ast)
    []
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
    env = __CALLER__
    check_placement!(env.module, :parse, @placement[:parse])
    Scope.put_attribute(env.module, :parse, func_ast)
    []
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
  defmacro directive(identifier, attrs \\ [], [do: block]) do
    env = __CALLER__
    check_placement!(env.module, :directive, @placement[:directive])
    scope(env, :directive, identifier, attrs, block)
    handle_desc(identifier)
  end

  @placement {:on, [under: :directive]}
  @doc """
  Declare a directive as operating an a AST node type

  See `directive/2`

  ## Placement

  #{Utils.placement_docs(@placement)}
  """
  defmacro on(ast_node) do
    env = __CALLER__
    check_placement!(env.module, :on, @placement[:on])
    ast_node
    |> List.wrap
    |> Enum.each(fn
      value ->
        Scope.put_attribute(
          env.module,
          :on,
          value,
          accumulate: true
        )
    end)
    []
  end

  @placement {:instruction, [under: :directive]}
  @doc """
  Calculate the instruction for a directive

  ## Placement

  #{Utils.placement_docs(@placement)}
  """
  defmacro instruction(func_ast) do
    env = __CALLER__
    check_placement!(env.module, :instruction, @placement[:instruction])
    Scope.put_attribute(env.module, :instruction, func_ast)
    []
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
  defmacro input_object(identifier, attrs \\ [], [do: block]) do
    env = __CALLER__
    check_placement!(env.module, :input_object, @placement[:input_object])
    scope(env, :input_object, identifier, attrs, block)
    handle_desc(identifier)
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
  defmacro union(identifier, attrs \\ [], [do: block]) do
    env = __CALLER__
    check_placement!(env.module, :union, @placement[:union])
    scope(env, :union, identifier, attrs, block)
    handle_desc(identifier)
  end

  @placement {:types, [under: [:union]]}
  @doc """
  Defines the types possible under a union type

  See `union/3`

  ## Placement

  #{Utils.placement_docs(@placement)}
  """
  defmacro types(types) do
    env = __CALLER__
    check_placement!(env.module, :types, @placement[:types])
    Scope.put_attribute(env.module, :types, List.wrap(types))
    []
  end

  # ENUMS

  @placement {:enum, [toplevel: true]}
  @doc """
  Defines an enum type

  ## Placement

  #{Utils.placement_docs(@placement)}
  """
  defmacro enum(identifier, attrs, [do: block]) do
    env = __CALLER__
    check_placement!(env.module, :enum, @placement[:enum])
    scope(env, :enum, identifier, attrs, block)
    handle_desc(identifier)
  end

  @doc """
  Defines an enum type

  See `enum/3`
  """
  defmacro enum(identifier, [do: block]) do
    env = __CALLER__
    check_placement!(env.module, :enum, @placement[:enum])
    scope(env, :enum, identifier, [], block)
    handle_desc(identifier)
  end
  defmacro enum(identifier, attrs) do
    env = __CALLER__
    check_placement!(env.module, :enum, @placement[:enum])
    scope(env, :enum, identifier, attrs, nil)
    handle_desc(identifier)
  end

  @placement {:value, [under: [:enum]]}
  @doc """
  Defines a value possible under an enum type

  See `enum/3`

  ## Placement

  #{Utils.placement_docs(@placement)}
  """
  defmacro value(identifier, raw_attrs \\ []) do
    env = __CALLER__
    check_placement!(env.module, :value, @placement[:value])

    attrs = raw_attrs
    |> Keyword.put(:value, Keyword.get(raw_attrs, :as, identifier))
    |> Keyword.delete(:as)
    |> add_description(env)

    Scope.put_attribute(env.module, :values, {identifier, attrs}, accumulate: true)
    []
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
  defmacro description(text_block) do
    text = reformat_description(text_block)
    env = __CALLER__
    check_placement!(env.module, :description, @placement[:description])
    Scope.put_attribute(env.module, :description, text)
    []
  end

  defp reformat_description(text), do: String.strip(text)

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
  ```
  """
  defmacro import_types(type_module_ast) do
    env = __CALLER__
    type_module_ast
    |> Macro.expand(env)
    |> do_import_types(env)

    []
  end

  defp do_import_types(type_module, env) when is_atom(type_module) do
    for {ident, name} <- type_module.__absinthe_types__ do
      if Enum.member?(type_module.__absinthe_exports__, ident) do
        put_definition(env.module, %Absinthe.Schema.Notation.Definition{
          category: :type,
          source: type_module,
          identifier: ident,
          attrs: [name: name],
          file: env.file,
          line: env.line})
      end
    end

    for {ident, name} <- type_module.__absinthe_directives__ do
      if Enum.member?(type_module.__absinthe_exports__, ident) do
        put_definition(env.module, %Absinthe.Schema.Notation.Definition{
          category: :directive,
          source: type_module,
          identifier: ident,
          attrs: [name: name],
          file: env.file,
          line: env.line})
      end
    end
  end
  defp do_import_types(type_module, _) do
    raise ArgumentError, """
    #{type_module} is not a module

    This macro must be given a literal module name or a macro which expands to a
    literal module name. Variables are not supported at this time.
    """
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

  # Define a notation scope that will accept attributes
  @doc false
  def scope(env, kind, identifier, attrs, block) do
    open_scope(kind, env, identifier, attrs)

    # this is probably too simple for now.
    block |> expand(env)

    close_scope(kind, env, identifier)
    []
  end

  defp expand(ast, env) do
    Macro.prewalk(ast, fn
      {:@, _, [{:desc, _, [desc]}]} ->
        Module.put_attribute(env.module, :__absinthe_desc__, desc)
      {_, _, _} = node -> Macro.expand(node, env)
      node -> node
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
    attrs = attrs
    |> add_reference(env, identifier)
    |> add_description(env)

    Scope.open(kind, env.module, attrs)
  end

  defp add_description(attrs, env) do
    case Module.get_attribute(env.module, :__absinthe_desc__) do
      nil ->
        attrs

      desc ->
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
      Type.Object, env, identifier,
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
    # Why is accumulate true not working here?
    # does that only work with the @ form?
    definitions = Module.get_attribute(module, :absinthe_definitions) || []
    Module.put_attribute(module, :absinthe_definitions, [definition | definitions])
  end

  defp close_scope_and_accumulate_attribute(attr_name, env, identifier) do
    Scope.put_attribute(env.module, attr_name, {identifier, close_scope_with_name(env.module, identifier)}, accumulate: true)
  end

  @doc false
  # Add the default name, if needed, to a struct
  def add_name(attrs, identifier, opts \\ []) do
    update_in(attrs, [:name], fn
      value ->
        default_name(identifier, value, opts)
    end)
  end

  # Find the name, or default as necessary
  defp default_name(identifier, nil, opts) do
    if opts[:title] do
      identifier |> Atom.to_string |> Utils.camelize
    else
      identifier |> Atom.to_string
    end
  end
  defp default_name(_, name, _) do
    name
  end

  @doc false
  # Check whether the provided operation is appropriate in the current
  # in the current scope context
  def check_placement!(mod, usage, kw_rules, opts \\ []) do
    do_check_placement!(mod, usage, Enum.into(List.wrap(kw_rules), %{}), opts)
  end
  defp do_check_placement!(mod, usage, %{under: parents} = rules, opts) do
    case Scope.current(mod) do
      %{name: name} ->
        if Enum.member?(List.wrap(parents), name) do
          do_check_placement!(mod, usage, Map.delete(rules, :under), opts)
        else
          raise Absinthe.Schema.Notation.Error, only_within(usage, parents, opts)
        end
      _ ->
        raise Absinthe.Schema.Notation.Error, only_within(usage, parents, opts)
    end
  end
  defp do_check_placement!(mod, usage, %{toplevel: true} = rules, opts) do
    case Scope.current(mod) do
      nil ->
        do_check_placement!(mod, usage, Map.delete(rules, :toplevel), opts)
      _ ->
        ref = opts[:as] || "`#{usage}`"
        raise Absinthe.Schema.Notation.Error, "Invalid schema notation: #{ref} must only be used toplevel"
    end
  end
  defp do_check_placement!(mod, usage, %{toplevel: false} = rules, opts) do
    case Scope.current(mod) do
      nil ->
        ref = opts[:as] || "`#{usage}`"
        raise Absinthe.Schema.Notation.Error, "Invalid schema notation: #{ref} must not be used toplevel"
      _ ->
        do_check_placement!(mod, usage, Map.delete(rules, :toplevel), opts)
    end
  end

  defp do_check_placement!(_, _, rules, _) when map_size(rules) == 0 do
    :ok
  end

  # The error message when a macro can only be used within a certain set of
  # parent scopes.
  defp only_within(usage, parents, opts) do
    ref = opts[:as] || "`#{usage}`"
    parts = List.wrap(parents)
    |> Enum.map(&"`#{&1}`")
    |> Enum.join(", ")
    "Invalid schema notation: #{ref} must only be used within #{parts}"
  end

end
