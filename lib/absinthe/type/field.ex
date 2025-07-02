defmodule Absinthe.Type.Field do
  alias Absinthe.Type

  @moduledoc """
  Used to define a field.

  Usually these are defined using `Absinthe.Schema.Notation.field/4`

  See the `t` type below for details and examples of how to define a field.
  """

  alias Absinthe.Type
  alias Absinthe.Type.Deprecation

  @typedoc """
  A resolver function.

  See the `Absinthe.Type.Field.t` explanation of `:resolve` for more information.
  """
  @type resolver_t ::
          (Absinthe.Resolution.arguments(), Absinthe.Resolution.t() -> result)
          | (Absinthe.Resolution.source(),
             Absinthe.Resolution.arguments(),
             Absinthe.Resolution.t() ->
               result)
          | {module(), atom()}

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
     the `Absinthe.Schema.Notation.field/4`. Including this option will bypass the snake_case to camelCase conversion.
  * `:description` - Description of a field, useful for introspection. If no description
     is provided, the field will inherit the description of its referenced type during
     introspection (e.g., a field of type `:user` will inherit the User type's description).
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
  something. Here's an example of defining a field that looks up a list of
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
          definition: module,
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
            # used by mutation fields
            triggers: [],
            middleware: [],
            complexity: nil,
            default_value: nil,
            __private__: [],
            definition: nil,
            __reference__: nil

  @doc false
  defdelegate functions, to: Absinthe.Blueprint.Schema.FieldDefinition
end
