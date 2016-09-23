defmodule Absinthe.Blueprint.Input.Argument do

  alias Absinthe.Blueprint

  @enforce_keys [:name, :source_location, :input_value]
  defstruct [
    :name,
    :input_value,
    :source_location,
    # Added by phases
    schema_node: nil,
    value: nil, # Value converted to native elixir value
    flags: %{},
    errors: [],
  ]

  @type t :: %__MODULE__{
    name: String.t,
    input_value: Blueprint.Input.Value.t,
    source_location: Blueprint.Document.SourceLocation.t,
    schema_node: nil | Absinthe.Type.Argument.t,
    value: any,
    flags: Blueprint.flags_t,
    errors: [Absinthe.Phase.Error.t],
  }

  @spec value_map([t]) :: %{atom => any}
  def value_map(arguments) do
    arguments
    |> Enum.flat_map(fn
      %__MODULE__{schema_node: nil} ->
        []
      %__MODULE__{schema_node: schema_node, value: value} ->
        [{
          schema_node.__reference__.identifier,
          value
        }]
    end)
    |> Enum.into(%{})
  end

end
