defmodule Absinthe.IR.Input do
  alias Absinthe.IR
  alias __MODULE__

  @type leaf :: Input.Integer.t
    | Input.Float.t
    | Input.Enum.t
    | Input.String.t
    | Input.Variable.t
    | Input.Boolean.t

  @type collection :: IR.Input.List.t | Input.Object.t

  @type t :: leaf | collection
end
