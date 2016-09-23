defmodule Absinthe.Resolution do
  @moduledoc """
  The primary piece of metadata passed to aid resolution functions, describing
  the current field's execution environment.
  """

  alias Absinthe.{Schema, Type}

  @typedoc """
  Information about the current resolution.

  ## Options
  - `:adapter` - The adapter used for any name conversions.
  - `:definition` - The Blueprint definition for this field. To access the
                    schema type for this field, see the `definition.schema_node`.
  - `:context` - The context passed to `Absinthe.run`.
  - `:root_value` - The root value passed to `Absinthe.run`, if any.
  - `:parent_type` - The parent type for the field.
  - `:schema` - The current schema.
  - `:source` - The resolved parent object; source of this field.
  """
  @type t :: %__MODULE__{
    adapter: Absinthe.Adapter.t,
    context: map,
    root_value: any,
    schema: Schema.t,
    definition: Blueprint.node_t,
    parent_type: Type.t,
    source: any,
  }

  @enforce_keys [:adapter, :context, :root_value, :schema, :source]
  defstruct [
    :adapter,
    :context,
    :parent_type,
    :root_value,
    :definition,
    :schema,
    :source,
  ]

end
