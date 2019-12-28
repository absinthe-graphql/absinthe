defmodule Absinthe.Type.Argument do
  @moduledoc """
  Used to define an argument.

  Usually these are defined using `Absinthe.Schema.Notation.arg/2`
  """

  alias Absinthe.Type

  use Type.Fetch

  @typedoc """
  Argument configuration

  * `:name` - The name of the argument, usually assigned automatically using `Absinthe.Schema.Notation.arg/2`.
  * `:type` - The type values the argument accepts/will coerce to.
  * `:deprecation` - Deprecation information for an argument, usually
    set-up using `Absinthe.Schema.Notation.deprecate/1`.
  * `:description` - Description of an argument, useful for introspection.
  """
  @type t :: %__MODULE__{
          name: binary,
          type: Type.identifier_t(),
          default_value: any,
          deprecation: Type.Deprecation.t() | nil,
          description: binary | nil,
          definition: module,
          __reference__: Type.Reference.t()
        }

  defstruct identifier: nil,
            name: nil,
            description: nil,
            type: nil,
            deprecation: nil,
            default_value: nil,
            definition: nil,
            __reference__: nil
end
