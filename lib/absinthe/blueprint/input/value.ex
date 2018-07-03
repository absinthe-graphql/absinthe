defmodule Absinthe.Blueprint.Input.Value do
  @moduledoc false

  # An input in a document.
  #
  # Used by arguments, input object fields, and input lists.

  @enforce_keys [:value]
  defstruct [
    :schema_node,
    :value,
    :data
  ]

  alias Absinthe.Blueprint.Input

  @type variable :: Input.Variable.t()
  @type literals ::
          Input.Integer.t()
          | Input.Float.t()
          | Input.Enum.t()
          | Input.String.t()
          | Input.Boolean.t()
          | Input.List.t()
          | Input.Object.t()
          | variable

  @type t :: %__MODULE__{
          value: literals | variable,
          data: term
        }

  @spec valid?(t) :: boolean
  @doc false
  # Whether a value is valid and useful in an argument
  def valid?(%{value: %Absinthe.Blueprint.Input.Null{}}), do: true
  def valid?(%{value: nil}), do: false
  def valid?(%{value: _}), do: true
end
