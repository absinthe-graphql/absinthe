defmodule Absinthe.Blueprint.Input.Argument do

  alias Absinthe.Blueprint

  @enforce_keys [:name, :literal_value, :source_location]
  defstruct [
    :name,
    :literal_value,
    :source_location,
    # Added by phases
    schema_node: nil,
    normalized_value: nil,
    data_value: nil,
    flags: [],
    errors: [],
  ]

  @type t :: %__MODULE__{
    name: String.t,
    literal_value: Blueprint.Input.t,
    source_location: Blueprint.Document.SourceLocation.t,
    schema_node: nil | Absinthe.Type.Argument.t,
    normalized_value: Blueprint.Input.t,
    data_value: any,
    flags: [atom],
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
