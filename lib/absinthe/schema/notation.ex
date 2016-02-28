defmodule Absinthe.Schema.Notation do
  alias Absinthe.Utils
  alias Absinthe.Type
  alias Absinthe.Schema.Notation.Scope
  alias Absinthe.Schema.Notation.Definition

  defmacro __using__(_opts) do
    quote do
      import unquote(__MODULE__), only: :macros
      Module.register_attribute __MODULE__, :absinthe_definitions, accumulate: true
      @before_compile unquote(__MODULE__).Writer
    end
  end

  Module.register_attribute(__MODULE__, :placement, accumulate: true)

  # OBJECT

  @doc """
  Define an object type.

  Adds an `Absinthe.Type.Object` to your schema.

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
  @placement {:object, [toplevel: true]}
  defmacro object(identifier, attrs, [do: block]) do
    scope(__CALLER__, :object, identifier, attrs, block)
  end
  defmacro object(identifier, [do: block]) do
    scope(__CALLER__, :object, identifier, [], block)
  end

  @doc """
  Declare implemented interfaces for an object.

  See also `interface/1`, which can be used for one interface,
  and `interface/3`, used to define interfaces themselves.

  ## Examples

  ```
  object :car do
    interfaces [:vehicle, :branded]
    # ...
  end
  ```
  """
  @placement {:interfaces, [under: :object]}
  defmacro interfaces(ifaces) when is_list(ifaces) do
    env = __CALLER__
    check_placement!(env.module, :interfaces)
    Scope.put_attribute(env.module, :interfaces, ifaces)
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
    check_placement!(env.module, :interface_attribute, as: "`interface` (as an attribute)")
    Scope.put_attribute(env.module, :interfaces, identifier, accumulate: true)
    []
  end

  # INTERFACES

  @doc """
  Define an interface type.

  Adds an `Absinthe.Type.Interface` to your schema.

  Also see `interface/1` and `interfaces/1`, which declare
  that an object implements one or more interfaces.

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
  @placement {:interface, [toplevel: :true]}
  defmacro interface(identifier, attrs, [do: block]) do
    scope(__CALLER__, :interface, identifier, attrs, block)
  end
  defmacro interface(identifier, [do: block]) do
    scope(__CALLER__, :interface, identifier, [], block)
  end

  @doc """
  Define a type resolver for a union or interface.

  See also:
  * `Absinthe.Type.Interface`
  * `Absinthe.Type.Union`

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
  @placement {:resolve_type, [under: [:interface, :union]]}
  defmacro resolve_type(func_ast) do
    env = __CALLER__
    check_placement!(env.module, :resolve_type)
    Scope.put_attribute(env.module, :resolve_type, func_ast)
    []
  end

  # FIELDS

  @placement {:field, [under: [:input_object, :interface, :object]]}
  defmacro field(identifier, [do: block]) do
    scope(__CALLER__, :field, identifier, [], block)
  end
  defmacro field(identifier, attrs) when is_list(attrs) do
    scope(__CALLER__, :field, identifier, attrs, nil)
  end
  defmacro field(identifier, type) do
    scope(__CALLER__, :field, identifier, [type: type], nil)
  end
  defmacro field(identifier, attrs, [do: block]) when is_list(attrs) do
    scope(__CALLER__, :field, identifier, attrs, block)
  end
  defmacro field(identifier, type, [do: block]) do
    scope(__CALLER__, :field, identifier, [type: type], block)
  end
  defmacro field(identifier, type, attrs) do
    scope(__CALLER__, :field, identifier, Keyword.put(attrs, :type, type),  nil)
  end
  defmacro field(identifier, type, attrs, [do: block]) do
    scope(__CALLER__, :field, identifier, Keyword.put(attrs, :type, type), block)
  end

  @placement {:resolve, [under: [:field]]}
  defmacro resolve(func_ast) do
    env = __CALLER__
    check_placement!(env.module, :resolve)
    Scope.put_attribute(env.module, :resolve, func_ast)
    []
  end

  @placement {:is_type_of, [under: [:object]]}
  defmacro is_type_of(func_ast) do
    env = __CALLER__
    check_placement!(env.module, :is_type_of)
    Scope.put_attribute(env.module, :is_type_of, func_ast)
    []
  end

  # ARGS

  @placement {:arg, [under: [:directive, :field]]}
  defmacro arg(identifier, type, attrs) do
    scope(__CALLER__, :arg, identifier, Keyword.put(attrs, :type, type), nil)
  end
  defmacro arg(identifier, attrs) when is_list(attrs) do
    scope(__CALLER__, :arg, identifier, attrs, nil)
  end
  defmacro arg(identifier, type) do
    scope(__CALLER__, :arg, identifier, [type: type], nil)
  end

  # SCALARS

  @placement {:scalar, [toplevel: true]}
  defmacro scalar(identifier, attrs, [do: block]) do
    scope(__CALLER__, :scalar, identifier, attrs, block)
  end
  defmacro scalar(identifier, [do: block]) do
    scope(__CALLER__, :scalar, identifier, [], block)
  end
  defmacro scalar(identifier, attrs) do
    scope(__CALLER__, :scalar, identifier, attrs, nil)
  end

  @placement {:serialize, [under: [:scalar]]}
  defmacro serialize(func_ast) do
    env = __CALLER__
    check_placement!(env.module, :serialize)
    Scope.put_attribute(env.module, :serialize, func_ast)
    []
  end

  @placement {:parse, [under: [:scalar]]}
  defmacro parse(func_ast) do
    env = __CALLER__
    check_placement!(env.module, :parse)
    Scope.put_attribute(env.module, :parse, func_ast)
    []
  end

  # DIRECTIVES

  @placement {:directive, [toplevel: true]}
  defmacro directive(identifier, attrs, [do: block]) do
    scope(__CALLER__, :directive, identifier, attrs, block)
  end
  defmacro directive(identifier, [do: block]) do
    scope(__CALLER__, :directive, identifier, [], block)
  end

  @doc """
  Declare a directive as operating an a AST node type
  """
  @placement {:on, [under: :directive]}
  defmacro on(ast_node) do
    env = __CALLER__
    check_placement!(env.module, :on)
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

  @doc """
  Calculate the instruction for a directive
  """
  @placement {:instruction, [under: :directive]}
  defmacro instruction(func_ast) do
    env = __CALLER__
    check_placement!(env.module, :instruction)
    Scope.put_attribute(env.module, :instruction, func_ast)
    []
  end

  # INPUT OBJECTS

  @placement {:input_object, [toplevel: true]}
  defmacro input_object(identifier, attrs, [do: block]) do
    scope(__CALLER__, :input_object, identifier, attrs, block)
  end
  defmacro input_object(identifier, [do: block]) do
    scope(__CALLER__, :input_object, identifier, [], block)
  end

  # UNIONS

  @placement {:union, [toplevel: true]}
  defmacro union(identifier, attrs, [do: block]) do
    scope(__CALLER__, :union, identifier, attrs, block)
  end
  defmacro union(identifier, [do: block]) do
    scope(__CALLER__, :union, identifier, [], block)
  end

  @placement {:types, [under: [:union]]}
  defmacro types(types) do
    env = __CALLER__
    check_placement!(env.module, :types)
    Scope.put_attribute(env.module, :types, List.wrap(types))
    []
  end

  # ENUMS

  @placement {:enum, [toplevel: true]}
  defmacro enum(identifier, attrs, [do: block]) do
    scope(__CALLER__, :enum, identifier, attrs, block)
  end
  defmacro enum(identifier, [do: block]) do
    scope(__CALLER__, :enum, identifier, [], block)
  end
  defmacro enum(identifier, attrs) do
    scope(__CALLER__, :enum, identifier, attrs, nil)
  end

  @placement {:value, [under: [:enum]]}
  defmacro value(identifier, raw_attrs \\ []) do
    env = __CALLER__
    check_placement!(env.module, :value)

    attrs = raw_attrs
    |> Keyword.put(:value, Keyword.get(raw_attrs, :as, identifier))
    |> Keyword.delete(:as)
    |> add_description_from_module_attribute(env.module)

    env = __CALLER__
    attrs |> add_description_from_module_attribute(env.module)
    Scope.put_attribute(env.module, :values, {identifier, attrs}, accumulate: true)
    []
  end

  # GENERAL ATTRIBUTES

  @placement {:description, [toplevel: false]}
  defmacro description(text_block) do
    text = reformat_description(text_block)
    quote bind_quoted: [notation: __MODULE__, text: text] do
      notation.check_placement!(__MODULE__, :description)
      Scope.put_attribute(__MODULE__, :description, text)
    end
  end

  defp reformat_description(text), do: String.strip(text)

  # IMPORTS

  @placement {:import_types, [toplevel: true]}
  defmacro import_types(type_module_ast, opts_ast \\ []) do
    env = __CALLER__
    opts = Macro.expand(opts_ast, env)
    type_module = Macro.expand(type_module_ast, env)

    for {ident, name} = naming <- type_module.__absinthe_types__ do
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

    []
  end

  defp put_definition(module, definition) do
    # Why is accumulate true not working here?
    # does that only work with the @ form?
    definitions = Module.get_attribute(module, :absinthe_definitions) || []
    Module.put_attribute(module, :absinthe_definitions, [definition | definitions])
  end

  # TYPE UTILITIES

  defmacro non_null(type) do
    quote do
      %Absinthe.Type.NonNull{of_type: unquote(type)}
    end
  end

  defmacro list_of(type) do
    quote do
      %Absinthe.Type.List{of_type: unquote(type)}
    end
  end

  # NOTATION UTILITIES

  @doc false
  # Define a notation scope that will accept attributes
  def scope(env, kind, identifier, attrs, block) do
    open_scope(kind, env, identifier, attrs)

    # this is probably too simple for now.
    block |> expand(env)

    close_scope(kind, env, identifier)
    []
  end

  defp expand(ast, env) do
    Macro.prewalk(ast, fn
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
      quote bind_quoted: [module: env.module, line: env.line, file: env.file, identifier: identifier], do: %{
        module: module,
        identifier: identifier,
        location: %{
          file: file,
          line: line
        }
      }
    )
  end

  @doc false
  # Support `@desc` descriptions
  def add_description_from_module_attribute(attrs_ast, mod) do
    case {attrs_ast[:description], Module.get_attribute(mod, :desc)} do
      {_, nil} ->
        attrs_ast
      {nil, doc} ->
        Module.put_attribute(mod, :desc, nil)
        Keyword.put(attrs_ast, :description, String.strip(doc))
      {_, _} ->
        attrs_ast
    end
  end

  # After verifying it is valid in the current context, open a new notation
  # scope, setting any provided attributes.
  defp open_scope(kind, env, identifier, attrs) do
    check_placement!(env.module, kind)
    Scope.open(kind, env.module, open_scope_attrs(attrs, identifier, env))
  end

  def open_scope_attrs(attrs, identifier, env) do
    attrs
    |> add_description_from_module_attribute(env.module)
    |> add_reference(env, identifier)
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

  def close_scope_with_name(mod, identifier, opts \\ []) do
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
  def check_placement!(mod, usage, opts \\ []) do
    rules = Keyword.get(@placement, usage, [])
    |> Enum.into(%{})
    do_check_placement!(mod, usage, rules, opts)
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
