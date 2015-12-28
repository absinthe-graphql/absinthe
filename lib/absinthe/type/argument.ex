defmodule Absinthe.Type.Argument do

  @moduledoc """
  The definition for an argument.

  Usually these are defined using the `Absinthe.Type.Definitions.args/1`
  convenience function.
  """

  alias __MODULE__
  alias Absinthe.Type

  @typedoc """
  Argument configuration

  * `:name` - The name of the argument, usually assigned automatically by
    the `Absinthe.Type.Definitions.args/1` convenience function.
  * `:type` - The type values the argument accepts/will coerce to.
  * `:deprecation` - Deprecation information for an argument, usually
    set-up using the `Absinthe.Type.Definitions.deprecate/1` convenience
    function.
  * `:description` - Description of an argument, useful for introspection.
  """
  @type t :: %{name: binary,
               type: Type.identifier_t,
               default_value: any,
               deprecation: Type.Deprecation.t | nil,
               description: binary | nil}

  defstruct name: nil, description: nil, type: nil, deprecation: nil, default_value: nil

  defimpl Absinthe.Validation.RequiredInput do

    # Whether the argument is required.
    #
    # * If the argument is deprecated, it is never required
    # * If the argumnet is not deprecated, it is required
    # if its type is non-null
    @doc false
    @spec required?(Argument.t) :: boolean
    def required?(%Argument{type: type, deprecation: nil}) do
      type
      |> Absinthe.Validation.RequiredInput.required?
    end
    def required?(%Argument{}) do
      false
    end

  end

end
