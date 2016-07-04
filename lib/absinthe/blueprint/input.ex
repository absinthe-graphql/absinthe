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

  @spec unwrap(t) :: any
  def unwrap(%{__struct__: mod, value: value}) when mod in [Input.Integer, Input.Float, Input.Enum, Input.String, Input.Boolean] do
    value
  end
  def unwrap(nil) do
    nil
  end
  # TODO: Support collection types

end
