defmodule Absinthe.Blueprint.Input.Value do
  @moduledoc false

  # An input in a document.
  #
  # Used by arguments, input object fields, and input lists.

  @enforce_keys [:raw, :normalized]
  defstruct [
    :schema_node,
    :raw,
    :normalized,
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
          raw: Input.RawValue.t(),
          normalized: literals,
          data: term
        }

  @spec valid?(t) :: boolean
  @doc false
  # Whether a value is valid and useful in an argument
  def valid?(%{normalized: %Absinthe.Blueprint.Input.Null{}}), do: true
  def valid?(%{normalized: nil}), do: false
  def valid?(%{normalized: _}), do: true
end
