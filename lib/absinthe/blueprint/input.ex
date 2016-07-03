defmodule Absinthe.Blueprint.Input do
  alias Absinthe.Blueprint
  alias __MODULE__

  @type leaf :: Input.Integer.t
    | Input.Float.t
    | Input.Enum.t
    | Input.String.t
    | Input.Variable.t
    | Input.Boolean.t

  @type collection :: Blueprint.Input.List.t | Input.Object.t

  @type t :: leaf | collection

end
