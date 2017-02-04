defmodule Absinthe.Complexity do
  alias Absinthe.{Blueprint, Schema}

  @enforce_keys [:context, :root_value, :schema, :definition]
  defstruct [:context, :root_value, :schema, :definition]

  @type t :: %__MODULE__{
    context: map,
    root_value: any,
    schema: Schema.t,
    definition: Blueprint.node_t
  }

end
