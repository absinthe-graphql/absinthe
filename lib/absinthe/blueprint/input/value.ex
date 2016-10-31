defmodule Absinthe.Blueprint.Input.Value do

  @moduledoc false

  # An input in a document.
  #
  # Used by arguments, input object fields, and input lists.

  @enforce_keys [:literal]
  defstruct [
    :schema_node,
    :literal,
    :normalized,
    :data,
  ]

  alias Absinthe.Blueprint.Input

  @type variable :: Input.Variable.t
  @type literals ::
    Input.Integer.t
  | Input.Float.t
  | Input.Enum.t
  | Input.String.t
  | Input.Boolean.t
  | Input.List.t
  | Input.Object.t
  | variable

  @type t :: %__MODULE__{
    literal: literals | variable,
    normalized: literals,
    data: term,
  }
end
