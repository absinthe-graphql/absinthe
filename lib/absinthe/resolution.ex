defmodule Absinthe.Resolution do
  @moduledoc """
  The primary piece of metadata passed to aid resolution functions, describing
  the current field's execution environment.
  """

  alias Absinthe.{Schema, Type}

  @typedoc """
  Information about the current resolution.

  ## Contents
  - `:adapter` - The adapter used for any name conversions.
  - `:definition` - The Blueprint definition for this field.
  - `:context` - The context passed to `Absinthe.run`.
  - `:root_value` - The root value passed to `Absinthe.run`, if any.
  - `:parent_type` - The parent type for the field.
  - `:schema` - The current schema.
  - `:source` - The resolved parent object; source of this field.

  To access the schema type for this field, see the `definition.schema_node`.
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

  @doc """
  Call a resolution function with its parent, args, and field Info

  When composing resolution functions, it is important to call this function
  instead of manually calling inner resolution functions. This is to support
  the various different forms that the resolution function can take:

  ### DO NOT
  ```elixir
  def authenticated(fun) do
    fn parent, args, info ->
      case info.context do
        %{current_user: _} ->
          fun.(parent, args, info) # THIS LINE IS WRONG
        _ ->
          {:error, "unauthorized"}
      end
    end
  end
  ```

  ### DO
  ```elixir
  def authenticated(fun) do
    fn parent, args, info ->
      case info.context do
        %{current_user: _} ->
          Absinthe.Resolution.call(fun, parent, args, info) # THIS LINE IS CORRECT
        _ ->
          {:error, "unauthorized"}
      end
    end
  end
  ```
  """
  def call(resolution_function, parent, args, field_info) do
    case resolution_function do
      fun when is_function(fun, 2) ->
        fun.(args, field_info)
      fun when is_function(fun, 3) ->
        fun.(parent, args, field_info)
      {mod, fun} ->
        apply(mod, fun, [parent, args, field_info])
      _ ->
        raise Absinthe.ExecutionError, """
        Field resolve property must be a 2 arity anonymous function, 3 arity
        anonymous function, or a `{Module, :function}` tuple.

        Instead got: #{inspect resolution_function}

        Info: #{inspect field_info}
        """
    end
  end

  def call(function, args, info) do
    call(function, info.source, args, info)
  end

end
