defmodule Absinthe.Type.Field do
  alias Absinthe.Type

  @moduledoc """
  Used to define a field.

  Usually these are defined using `Absinthe.Schema.Notation.field/4`

  See the `t` type below for details and examples of how to define a field.
  """

  alias Absinthe.Type
  alias Absinthe.Type.Deprecation
  alias Absinthe.Schema

  use Type.Fetch

  @typedoc """
  A resolver function.

  See the `Absinthe.Type.Field.t` explanation of `:resolve` for more information.
  """
  @type resolver_t :: (%{atom => any}, Absinthe.Resolution.t() -> result)

  @typedoc """
  The result of a resolver.
  """
  @type result :: ok_result | error_result | middleware_result

  @typedoc """
  A complexity function.

  See the `Absinthe.Type.Field/t` explanation of `:complexity` for more
  information.
  """
  @type complexity_t ::
          (%{atom => any}, non_neg_integer -> non_neg_integer)
          | (%{atom => any}, non_neg_integer, Absinthe.Complexity.t() -> non_neg_integer)
          | {module, atom}
          | non_neg_integer

  @type ok_result :: {:ok, any}
  @type error_result :: {:error, error_value}
  @type middleware_result :: {:middleware, Absinthe.Middleware.spec(), term}

  @typedoc """
  An error message is a human-readable string describing the error that occurred.
  """
  @type error_message :: String.t()

  @typedoc """
  Any serializable value.
  """
  @type serializable :: any

  @typedoc """
  A custom error may be a `map` or a `Keyword.t`, but must contain a `:message` key.

  Note that the values that make up a custom error must be serializable.
  """
  @type custom_error ::
          %{required(:message) => error_message, optional(atom) => serializable} | Keyword.t()

  @typedoc """
  An error value is a simple error message, a custom error, or a list of either/both of them.
  """
  @type error_value ::
          error_message | custom_error | [error_message | custom_error] | serializable

  @typedoc """
  The configuration for a field.

  * `:name` - The name of the field, usually assigned automatically by
     the `Absinthe.Schema.Notation.field/1`.
  * `:description` - Description of a field, useful for introspection.
  * `:deprecation` - Deprecation information for a field, usually
     set-up using `Absinthe.Schema.Notation.deprecate/1`.
  * `:type` - The type the value of the field should resolve to
  * `:args` - The arguments of the field, usually created by using `Absinthe.Schema.Notation.arg/2`.
  * `:resolve` - The resolution function. See below for more information.
  * `:complexity` - The complexity function. See below for more information.
  * `:default_value` - The default value of a field. Note this is not used during resolution; only fields that are part of an `Absinthe.Type.InputObject` should set this value.

  ## Resolution Functions

  ### Default

  If no resolution function is given, the default resolution function is used,
  which is roughly equivalent to this:

      {:ok, Map.get(parent_object, field_name)}

  This is commonly use when listing the available fields on a
  `Absinthe.Type.Object` that models a data record. For instance:

  ```
  object :person do
    description "A person"

    field :first_name, :string
    field :last_name, :string
  end
  ```
  ### Custom Resolution

  When accepting arguments, however, you probably need to use them for
  something. Here's an example of definining a field that looks up a list of
  users for a given `location_id`:
  ```
  query do
    field :users, :person do
      arg :location_id, non_null(:id)

      resolve fn %{location_id: id}, _ ->
        {:ok, MyApp.users_for_location_id(id)}
      end
    end
  end
  ```

  Custom resolution functions are passed two arguments:

  1. A map of the arguments for the field, filled in with values from the
     provided query document/variables.
  2. An `Absinthe.Resolution` struct, containing the execution environment
     for the field (and useful for complex resolutions using the resolved source
     object, etc)

  ## Complexity function

  ### Default

  If no complexity function is given, the default complexity function is used,
  which is equivalent to:

      fn(_, child_complexity) -> 1 + child_complexity end

  ### Custom Complexity

  When accepting arguments, however, you probably need to use them for
  something. Here's an example of defining a field that looks up at most
  `limit` users:
  ```
  query do
    field :users, :person do
      arg :limit, :integer

      complexity fn %{limit: limit}, child_complexity ->
        10 + limit * child_complexity
      end
    end
  end
  ```

  An optional third argument, `Absinthe.Complexity` struct, provides extra
  information. Here's an example of changing the complexity using the context:
  ```
  query do
    field :users, :person do
      arg :limit, :integer

      complexity fn _, child_complexity, %{context: %{admin: admin?}} ->
        if admin?, do: 0, else: 10 + limit * child_complexity
      end
    end
  end
  ```

  Custom complexity functions are passed two or three arguments:

  1. A map of the arguments for the field, filled in with values from the
     provided query document/variables.
  2. A non negative integer, which is total complexity of the child fields.
  3. An `Absinthe.Complexity` struct with information about the context of the
     field. This argument is optional when using an anonymous function.

  Alternatively complexity can be an integer greater than or equal to 0:
  ```
  query do
    field :users, :person do
      complexity 10
    end
  end
  ```

  """
  @type t :: %__MODULE__{
          identifier: atom,
          name: binary,
          description: binary | nil,
          type: Type.identifier_t(),
          deprecation: Deprecation.t() | nil,
          default_value: any,
          args: %{(binary | atom) => Absinthe.Type.Argument.t()} | nil,
          middleware: [],
          complexity: complexity_t | nil,
          __private__: Keyword.t(),
          __reference__: Type.Reference.t()
        }

  defstruct identifier: nil,
            name: nil,
            description: nil,
            type: nil,
            deprecation: nil,
            args: %{},
            # used by subscription fields
            config: nil,
            # used by mutatino fields
            triggers: [],
            middleware: [],
            complexity: nil,
            default_value: nil,
            __private__: [],
            __reference__: nil

  @doc """
  Build an AST of the field map for inclusion in other types

  ## Examples

  ```
  iex> build([foo: [type: :string], bar: [type: :integer]])
  {:%{}, [],
   [foo: {:%, [],
     [{:__aliases__, [alias: false], [:Absinthe, :Type, :Field]},
      {:%{}, [], [name: "Foo", type: :string]}]},
    bar: {:%, [],
     [{:__aliases__, [alias: false], [:Absinthe, :Type, :Field]},
      {:%{}, [], [name: "Bar", type: :integer]}]}]}
  ```
  """
  @spec build(Keyword.t()) :: tuple
  def build(fields) when is_list(fields) do
    quoted_empty_map = quote do: %{}

    ast =
      for {field_name, field_attrs} <- fields do
        name = field_name |> Atom.to_string()
        default_ref = field_attrs[:__reference__]

        field_attrs =
          case Keyword.pop(field_attrs, :resolve) do
            {nil, field_attrs} ->
              field_attrs

            {resolution_function_ast, field_attrs} ->
              Keyword.put(field_attrs, :middleware, [
                {Absinthe.Resolution, resolution_function_ast}
              ])
          end

        field_data =
          field_attrs
          |> Keyword.put_new(:name, name)
          |> Keyword.put(:identifier, field_name)
          |> Keyword.update(:middleware, [], &Enum.reverse/1)
          |> Keyword.update(:args, quoted_empty_map, fn raw_args ->
            args =
              for {name, attrs} <- raw_args,
                  do: {name, ensure_reference(attrs, name, default_ref)}

            Type.Argument.build(args)
          end)

        field_ast =
          quote do: %Absinthe.Type.Field{
                  unquote_splicing(field_data |> Absinthe.Type.Deprecation.from_attribute())
                }

        {field_name, field_ast}
      end

    quote do: %{unquote_splicing(ast)}
  end

  defp ensure_reference(arg_attrs, name, default_reference) do
    case Keyword.has_key?(arg_attrs, :__reference__) do
      true ->
        arg_attrs

      false ->
        # default_reference is map AST, hence the gymnastics to build it nicely.
        {a, b, args} = default_reference

        Keyword.put(arg_attrs, :__reference__, {a, b, Keyword.put(args, :identifier, name)})
    end
  end

  defimpl Absinthe.Traversal.Node do
    def children(node, traversal) do
      found = Schema.lookup_type(traversal.context, node.type)

      if found do
        [found | node.args |> Map.values()]
      else
        type_names = traversal.context.types.by_identifier |> Map.keys() |> Enum.join(", ")

        raise "Unknown Absinthe type for field `#{node.name}': (#{node.type |> Type.unwrap()} not in available types, #{
                type_names
              })"
      end
    end
  end
end
