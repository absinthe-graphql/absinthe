defmodule Absinthe.Type.Argument do

  alias __MODULE__
  alias Absinthe.Type

  @type t :: %{name: binary,
               type: Type.identifier_t,
               default_value: any,
               deprecation: Type.Deprecation.t | nil,
               description: binary | nil}

  defstruct name: nil, description: nil, type: nil, deprecation: nil, default_value: nil

  defimpl Absinthe.Validation.RequiredInput do

    @doc """
    Whether the argument is required.

    * If the argument is deprecated, it is never required
    * If the argumnet is not deprecated, it is required
    if its type is non-null
    """
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
