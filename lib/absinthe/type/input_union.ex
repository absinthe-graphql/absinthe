defmodule Absinthe.Type.InputUnion do
  @moduledoc """
  An InputUnion is an abstract type made up of multiple possible concrete types.

  No common fields are declared in an input union. Compare to `Absinthe.Type.Interface`.

  Because it's necessary for the input union to determine the concrete type of a
  resolved input object, you must either:
  ```
  input_union :search_query do
    description "A search query"

    types [:person, :business]
  end
  ```
  """

  use Absinthe.Introspection.Kind

  alias Absinthe.Type

  @typedoc """
  * `:name` - The name of the input union type. Should be a TitleCased `binary`. Set automatically.
  * `:description` - A nice description for introspection.
  * `:types` - The list of possible types.

  The `__private__` and `:__reference__` keys are for internal use.

  """
  @type t :: %__MODULE__{
          name: binary,
          description: binary,
          types: [Type.identifier_t()],
          identifier: atom,
          __private__: Keyword.t(),
          __reference__: Type.Reference.t(),
          default_type: Type.identifier_t()
        }

  defstruct name: nil,
            description: nil,
            identifier: nil,
            types: [],
            __private__: [],
            __reference__: nil,
            default_type: nil

  def build(%{attrs: attrs}) do
    quote do: %unquote(__MODULE__){unquote_splicing(attrs)}
  end

  @doc false
  @spec member?(t, Type.t()) :: boolean
  def member?(%{types: types}, %{__reference__: %{identifier: ident}}) do
    ident in types
  end

  def member?(_, _) do
    false
  end
end
