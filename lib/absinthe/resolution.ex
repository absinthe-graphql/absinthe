defmodule Absinthe.Resolution do
  @moduledoc """
  The primary piece of metadata passed to aid resolution functions, describing
  the current field's execution environment.
  """

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
    state: field_state,
    acc: %{any => any},
  }

  @enforce_keys [:adapter, :context, :root_value, :schema, :source]
  defstruct [
    :result,
    :adapter,
    :context,
    :parent_type,
    :root_value,
    :definition,
    :schema,
    :source,
    errors: [],
    middleware: [],
    acc: %{},
    arguments: %{},
    state: :cont,
  ]

  def resolver(fun) do
    Absinthe.Resolution.Middleware.plug(__MODULE__, fun)
  end

  @type field_state :: :resolving | :halted | :suspended

  def call(%{state: :cont} = res, resolution_function) do
    result = case resolution_function do
      fun when is_function(fun, 2) ->
        fun.(res.arguments, res)
      fun when is_function(fun, 3) ->
        fun.(res.source, res.arguments, res)
      {mod, fun} ->
        apply(mod, fun, [res.source, res.arguments, res])
      _ ->
        raise Absinthe.ExecutionError, """
        Field resolve property must be a 2 arity anonymous function, 3 arity
        anonymous function, or a `{Module, :function}` tuple.

        Instead got: #{inspect resolution_function}

        Info: #{inspect res}
        """
    end

    apply_result(res, result)
  end

  @doc "Handy function for applying user function result tuples to a resolution struct"
  def apply_result(res, {:ok, value}) do
    %{res | result: value}
  end
  def apply_result(res, {:error, [{_, _} | _] = error_keyword}) do
    %{res | errors: [error_keyword]}
  end
  def apply_result(res, {:error, errors}) do
    %{res | errors: List.wrap(errors)}
  end
  def apply_result(res, {:plugin, module, opts}) do
    apply_result(res, {:middleware, module, opts})
  end
  def apply_result(res, {:middleware, module, opts}) do
    %{res | middleware: [Absinthe.Resolution.Middleware.plug(module, opts) | res.middleware]}
  end
  def apply_result(res, result) do
    raise result_error(result, res.definition, res.source)
  end

  @doc false
  def result_error({:error, _} = value, field, source) do
    result_error(
      value, field, source,
      "You're returning an :error tuple, but did you forget to include a `:message`\nkey in every custom error (map or keyword list)?"
    )
  end
  def result_error(value, field, source) do
    result_error(
      value, field, source,
      "Did you forget to return a valid `{:ok, any}` | `{:error, error_value}` tuple?"
    )
  end

  @doc """
  TODO: Deprecate
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

  @error_detail """
  ## For a data result

  `{:ok, any}` result will do.

  ### Examples:

  A simple integer result:

      {:ok, 1}

  Something more complex:

      {:ok, %Model.Thing{some: %{complex: :data}}}

  ## For an error result

  One or more errors for a field can be returned in a single `{:error, error_value}` tuple.

  `error_value` can be:
  - A simple error message string.
  - A map containing `:message` key, plus any additional serializable metadata.
  - A keyword list containing a `:message` key, plus any additional serializable metadata.
  - A list containing multiple of any/all of these.

  ### Examples

  A simple error message:

      {:error, "Something bad happened"}

  Multiple error messages:

      {:error, ["Something bad", "Even worse"]

  Single custom errors (note the required `:message` keys):

      {:error, message: "Unknown user", code: 21}
      {:error, %{message: "A database error occurred", details: format_db_error(some_value)}}

  Three errors of mixed types:

      {:error, ["Simple message", [message: "A keyword list error", code: 1], %{message: "A map error"}]}

  ## To activate a plugin

  `{:plugin, NameOfPluginModule, term}` to activate a plugin.

  See `Absinthe.Resolution.Plugin` for more information.

  """
  def result_error(value, field, source, guess) do
    Absinthe.ExecutionError.exception("""
    Invalid value returned from resolver.

    Resolving field:

        #{field.name}

    Defined at:

        #{field.schema_node.__reference__.location.file}:#{field.schema_node.__reference__.location.line}

    Resolving on:

        #{inspect source}

    Got value:

        #{inspect value}

    ...

    #{guess}

    ...

    The result must be one of the following...

    #{@error_detail}
    """)
  end
end
