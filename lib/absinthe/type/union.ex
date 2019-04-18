defmodule Absinthe.Type.Union do
  @moduledoc """
  A unions is an abstract type made up of multiple possible concrete types.

  No common fields are declared in a union. Compare to `Absinthe.Type.Interface`.

  Because it's necessary for the union to determine the concrete type of a
  resolved object, you must either:

  * Provide a `:resolve_type` function on the union
  * Provide a `:is_type_of` function on each possible concrete type

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

  use Absinthe.Introspection.Kind

  alias Absinthe.{Schema, Type}

  @typedoc """
  * `:name` - The name of the union type. Should be a TitleCased `binary`. Set automatically.
  * `:description` - A nice description for introspection.
  * `:types` - The list of possible types.
  * `:resolve_type` - A function used to determine the concrete type of a resolved object. See also `Absinthe.Type.Object`'s `:is_type_of`. Either `resolve_type` is specified in the union type, or every object type in the union must specify `is_type_of`

  The `:resolve_type` function will be passed two arguments; the object whose type needs to be identified, and the `Absinthe.Execution` struct providing the full execution context.

  The `__private__` and `:__reference__` keys are for internal use.

  """
  @type t :: %__MODULE__{
          name: binary,
          description: binary,
          types: [Type.identifier_t()],
          identifier: atom,
          fields: map,
          __private__: Keyword.t(),
          definition: module,
          __reference__: Type.Reference.t()
        }

  defstruct name: nil,
            description: nil,
            identifier: nil,
            resolve_type: nil,
            types: [],
            fields: nil,
            __private__: [],
            definition: nil,
            __reference__: nil

  @doc false
  defdelegate functions, to: Absinthe.Blueprint.Schema.UnionTypeDefinition

  @doc false
  @spec member?(t, Type.t()) :: boolean
  def member?(%{types: types}, %{identifier: ident}) do
    ident in types
  end

  def member?(_, _) do
    false
  end

  @doc false
  @spec resolve_type(t, any, Absinthe.Resolution.t()) :: Type.t() | nil
  def resolve_type(type, object, env, opts \\ [lookup: true])

  def resolve_type(%{types: types} = union, obj, %{schema: schema} = env, opts) do
    if resolver = Type.function(union, :resolve_type) do
      case resolver.(obj, env) do
        nil ->
          nil

        ident when is_atom(ident) ->
          if opts[:lookup] do
            Absinthe.Schema.lookup_type(schema, ident)
          else
            ident
          end
      end
    else
      type_name =
        Enum.find(types, fn
          %{is_type_of: nil} ->
            false

          type ->
            type = Absinthe.Schema.lookup_type(schema, type)
            Absinthe.Type.function(type, :is_type_of).(obj)
        end)

      if opts[:lookup] do
        Schema.lookup_type(schema, type_name)
      else
        type_name
      end
    end
  end
end
