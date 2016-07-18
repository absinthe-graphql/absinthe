defmodule Absinthe.Blueprint.Input.Argument do

  alias Absinthe.Blueprint

  @enforce_keys [:name, :value]
  defstruct [
    :name,
    :value,
    # Added by phases
    schema_node: nil,
    normalized_value: nil,
    errors: [],
  ]

  @type t :: %__MODULE__{
    name: String.t,
    value: Blueprint.Input.t,
    schema_node: nil | Absinthe.Type.Argument.t,
    normalized_value: Blueprint.Input.t,
    errors: [Absinthe.Phase.Error.t],
  }

  @spec value_map([t]) :: %{atom => any}
  def value_map(arguments) do
    arguments
    |> Enum.flat_map(fn
      %__MODULE__{schema_node: nil} ->
        []
      %__MODULE__{schema_node: schema_node, normalized_value: value} ->
        [{
          schema_node.__reference__.identifier,
          value
        }]
    end)
    |> Enum.into(%{})
  end

end
