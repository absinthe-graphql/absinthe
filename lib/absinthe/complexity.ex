defmodule Absinthe.Complexity do
  @moduledoc """
  Extra metadata passed to aid complexity analysis functions, describing the
  current field's environment.
  """
  alias Absinthe.{Blueprint, Schema}

  @enforce_keys [:context, :root_value, :schema, :definition]
  defstruct [:context, :root_value, :schema, :definition]

  @typedoc """
  - `:definition` - The Blueprint definition for this field.
  - `:context` - The context passed to `Absinthe.run`.
  - `:root_value` - The root value passed to `Absinthe.run`, if any.
  - `:schema` - The current schema.
  """
  @type t :: %__MODULE__{
          definition: Blueprint.node_t(),
          context: map,
          root_value: any,
          schema: Schema.t()
        }
end
