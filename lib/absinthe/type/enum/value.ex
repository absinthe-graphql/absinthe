defmodule Absinthe.Type.Enum.Value do
  @moduledoc """
  A possible value for an enum.

  See `Absinthe.Type.Enum` and `Absinthe.Schema.Notation.value/1`.
  """

  alias Absinthe.Type

  @typedoc """
  A defined enum value entry.

  Generally defined using `Absinthe.Schema.Notation.value/2` as
  part of a schema.

  * `:name` - The name of the value. This is also the incoming, external
    value that will be provided by query documents.
  * `:description` - A nice description for introspection.
  * `:value` - The raw, internal value that `:name` map to. This will be
    provided as the argument value to `resolve` functions.
  * `:deprecation` - Deprecation information for a value, usually
    set-up using the `Absinthe.Schema.Notation.deprecate/1` convenience
    function.
  """
  @type t :: %{
          name: binary,
          description: binary,
          value: any,
          enum_identifier: atom,
          deprecation: Type.Deprecation.t() | nil,
          __reference__: Type.Reference.t()
        }
  defstruct name: nil,
            description: nil,
            value: nil,
            deprecation: nil,
            enum_identifier: nil,
            __reference__: nil
end
