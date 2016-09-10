defmodule Absinthe.Phase.Document.Execution.Resolution.Info do

  @moduledoc """
  Information passed to aid resolution functions, describing the current field's
  execution environment.
  """

  @typedoc """

  ## Options
  - `:context` - The context passed to `Absinthe.run`.
  - `:root_value` - The root value passed to `Absinthe.run`, if any.
  - `:schema` - The current schema.
  - `:source` - The resolved parent object; source of this field.
  """
  @type t :: %__MODULE__{
    context: map,
    root_value: any,
    schema: Schema.t,
    source: any,
  }

  @enforce_keys [:context, :root_value, :schema, :source]
  defstruct [
    :context,
    :root_value,
    :schema,
    :source,
  ]

end
