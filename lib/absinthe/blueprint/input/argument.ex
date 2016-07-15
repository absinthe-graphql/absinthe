defmodule Absinthe.Blueprint.Input.Argument do

  alias Absinthe.Blueprint

  @enforce_keys [:name, :value]
  defstruct [
    :name,
    :value,
    # Added by phases
    schema_node: nil,
    provided_value: nil,
    errors: [],
  ]

  @type t :: %__MODULE__{
    name: String.t,
    value: Blueprint.Input.t,
    schema_node: nil | Absinthe.Type.Argument.t,
    provided_value: Blueprint.Input.t,
    errors: [Absinthe.Phase.Error.t],
  }

  @spec value_map([t]) :: %{atom => any}
  def value_map(arguments) do
    arguments
    |> Enum.flat_map(fn
      %__MODULE__{schema_node: nil, value: value} ->
        []
      %__MODULE__{schema_node: schema_node, value: value} ->
        {
          schema_node.name |> String.to_existing_atom,
          value
        }
    end)
    |> Enum.into(%{})
  end

end
